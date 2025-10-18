terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}



# -----------------------------------------------------------------------------
# Probes (AWS CLI) safe in CI; avoids hard failures of data sources.
# -----------------------------------------------------------------------------


locals {
  github_oidc_url = "https://token.actions.githubusercontent.com"

  provider_exists_hint = length(trimspace(var.existing_oidc_provider_arn)) > 0
  role_exists_hint     = length(trimspace(var.existing_role_arn)) > 0

  create_provider = var.create_oidc_provider && !local.provider_exists_hint
  create_role     = var.create_oidc_role     && !local.role_exists_hint
}

resource "aws_iam_openid_connect_provider" "this" {
  count           = local.create_provider ? 1 : 0
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [var.github_thumbprint]
  url             = local.github_oidc_url
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        for repo in var.repositories :
        "repo:%{if length(regexall(":+", repo)) > 0}${repo}%{else}${repo}:*%{endif}"
      ]
    }

    principals {
      type = "Federated"
      identifiers = [
        # prefer newly created provider, else the known-existing one, else optional var.oidc_provider_arn
        try(aws_iam_openid_connect_provider.this[0].arn, ""),
        var.existing_oidc_provider_arn,
        var.oidc_provider_arn,
      ]
    }
  }
}

resource "aws_iam_role" "this" {
  count                = local.create_role ? 1 : 0
  name                 = var.role_name
  description          = var.role_description
  max_session_duration = var.max_session_duration
  assume_role_policy   = data.aws_iam_policy_document.assume_role.json
  tags                 = var.tags
  depends_on           = [aws_iam_openid_connect_provider.this]
}

# Attach to the *effective* role name: if existing, use var.role_name (same name); else created one has same name.
locals {
  effective_role_name = var.role_name
}

resource "aws_iam_role_policy_attachment" "attach" {
  count      = length(var.oidc_role_attach_policies)
  policy_arn = var.oidc_role_attach_policies[count.index]
  role       = local.effective_role_name
  depends_on = [aws_iam_role.this]
}