terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

locals {
  github_oidc_url  = "https://token.actions.githubusercontent.com"
  # Create the provider only if caller asked AND no ARN was provided
  create_provider  = var.create_oidc_provider && length(trimspace(var.oidc_provider_arn)) == 0
}

# Create OIDC provider if requested (count known at plan time)
resource "aws_iam_openid_connect_provider" "this" {
  count           = local.create_provider ? 1 : 0
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [var.github_thumbprint]
  url             = local.github_oidc_url
}

# Pick the provider ARN for the trust policy:
# 1) the one we just created (if any)  2) or the provided ARN (if any)  3) else empty string
locals {
  created_provider_arn   = try(aws_iam_openid_connect_provider.this[0].arn, "")
  federated_provider_arn = length(local.created_provider_arn) > 0 ? local.created_provider_arn : trimspace(coalesce(var.oidc_provider_arn, ""))
}

# Trust policy (no count needed)
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    # Allow org/repo:ref if provided, otherwise org/repo:* (all refs)
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        for repo in var.repositories :
        (length(regexall(":", repo)) > 0) ? "repo:${repo}" : "repo:${repo}:*"
      ]
    }

    principals {
      type        = "Federated"
      identifiers = [local.federated_provider_arn]
    }
  }
}

# Create role (count known at plan time)
resource "aws_iam_role" "this" {
  count                = var.create_oidc_role ? 1 : 0
  name                 = var.role_name
  description          = var.role_description
  max_session_duration = var.max_session_duration
  assume_role_policy   = data.aws_iam_policy_document.assume_role.json
  tags                 = var.tags

  lifecycle {
    precondition {
      condition     = length(local.federated_provider_arn) > 0
      error_message = "No OIDC provider ARN available for the trust policy. Provide oidc_provider_arn or allow the module to create one."
    }
  }
}


resource "aws_iam_role_policy_attachment" "attach" {
  count      = var.create_oidc_role ? length(var.oidc_role_attach_policies) : 0
  policy_arn = var.oidc_role_attach_policies[count.index]
  role       = aws_iam_role.this[0].name
  depends_on = [aws_iam_role.this]
}
