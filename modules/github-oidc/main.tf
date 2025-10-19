terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# -----------------------------
# Inputs-only creation gates
# -----------------------------
locals {
  github_oidc_url = "https://token.actions.githubusercontent.com"

  # Create the provider only if the caller asked AND no existing ARN was provided.
  create_provider  = var.create_oidc_provider && length(trimspace(var.existing_oidc_provider_arn)) == 0

  # Create the role only if the caller asked AND no existing role ARN was provided.
  # (Do NOT block on provider inputs; trust policy will pick provider via created/input/probe.)
  create_role_gate = var.create_oidc_role && length(trimspace(var.existing_role_arn)) == 0
}

# -------------------------------------------------------------
# Optional probes (NEVER used for count; only for convenience)
# -------------------------------------------------------------
data "external" "oidc_provider_probe" {
  program = [
    "bash", "-c", <<-EOT
      set -euo pipefail
      FOUND=""
      ARNS=$(aws iam list-open-id-connect-providers --query 'OpenIDConnectProviderList[].Arn' --output text 2>/dev/null || true)
      for A in $ARNS; do
        URL=$(aws iam get-open-id-connect-provider --open-id-connect-provider-arn "$A" --query 'Url' --output text 2>/dev/null || true)
        if [ "$URL" = "https://token.actions.githubusercontent.com" ]; then
          FOUND="$A"; break
        fi
      done
      echo "{\"arn\":\"$FOUND\"}"
    EOT
  ]
}

data "external" "oidc_role_probe" {
  program = [
    "bash", "-c", <<-EOT
      set -euo pipefail
      NAME="${var.role_name}"
      ARN=$(aws iam get-role --role-name "$NAME" --query 'Role.Arn' --output text 2>/dev/null || echo "")
      if [ -n "$ARN" ] && [ "$ARN" != "None" ] && [ "$ARN" != "null" ]; then
        echo "{\"arn\":\"$ARN\"}"
      else
        echo "{\"arn\":\"\"}"
      fi
    EOT
  ]
}

# -------------------------------------------------------------
# Create OIDC provider only if inputs say to (count known at plan)
# -------------------------------------------------------------
resource "aws_iam_openid_connect_provider" "this" {
  count           = local.create_provider ? 1 : 0
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [var.github_thumbprint]
  url             = local.github_oidc_url
}

# --------------------------------------------------------------------
# Provider ARN to trust in the role (single-line ternary to avoid parse issues)
# Order: created → explicit input → probe (for display/trust fill-in)
# --------------------------------------------------------------------
locals {
  created_provider_arn   = try(aws_iam_openid_connect_provider.this[0].arn, "")
  federated_provider_arn = length(local.created_provider_arn) > 0 ? local.created_provider_arn : (length(trimspace(var.existing_oidc_provider_arn)) > 0 ? trimspace(var.existing_oidc_provider_arn) : trimspace(try(data.external.oidc_provider_probe.result.arn, "")))
}

# -------------------------------------------------------------
# Trust policy (no count; unknowns resolve safely at apply time)
# -------------------------------------------------------------
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    # Allow specific repos:
    # - if repo string includes a ref (org/repo:ref), use it
    # - else allow all refs for that repo (org/repo:*)
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        for repo in var.repositories :
        length(regexall(":", repo)) > 0 ? "repo:${repo}" : "repo:${repo}:*"
      ]
    }

    principals {
      type        = "Federated"
      identifiers = [local.federated_provider_arn]
    }
  }
}

# -------------------------------------------------------------
# Create role only if inputs say to (count known at plan)
# -------------------------------------------------------------
resource "aws_iam_role" "this" {
  count                = local.create_role_gate ? 1 : 0
  name                 = var.role_name
  description          = var.role_description
  max_session_duration = var.max_session_duration
  assume_role_policy   = data.aws_iam_policy_document.assume_role.json
  tags                 = var.tags

  # Clear error if we somehow lack a provider ARN at apply time.
  lifecycle {
    precondition {
      condition     = length(local.federated_provider_arn) > 0
      error_message = "No OIDC provider ARN available for the trust policy. Either set existing_oidc_provider_arn, allow the module to create one, or ensure the probe can discover it."
    }
  }
}

resource "aws_iam_role_policy_attachment" "attach" {
  count      = local.create_role_gate ? length(var.oidc_role_attach_policies) : 0
  policy_arn = var.oidc_role_attach_policies[count.index]
  role       = aws_iam_role.this[0].name
  depends_on = [aws_iam_role.this]
}
