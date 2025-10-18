locals {
  provider_exists_hint = length(trimspace(var.existing_oidc_provider_arn)) > 0
  role_exists_hint     = length(trimspace(var.existing_role_arn)) > 0

  create_provider = var.create_oidc_provider && !local.provider_exists_hint
  create_role     = var.create_oidc_role && !local.role_exists_hint
}

# Detect if OIDC provider exists
data "aws_iam_openid_connect_provider" "existing" {
  count = length(var.existing_oidc_provider_arn) > 0 ? 1 : 0
  arn   = var.existing_oidc_provider_arn
}

# Create OIDC provider (only if not already exists)
resource "aws_iam_openid_connect_provider" "this" {
  count           = var.create_oidc_provider ? 1 : 0
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [var.github_thumbprint]
  url             = "https://token.actions.githubusercontent.com"
}

# Trust Policy for Role
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
        try(aws_iam_openid_connect_provider.this[0].arn, ""),
        var.existing_oidc_provider_arn,
      ]
    }
  }
}

# Role (create only if missing)
resource "aws_iam_role" "this" {
  count                = var.create_oidc_role ? 1 : 0
  name                 = var.role_name
  description          = var.role_description
  max_session_duration = var.max_session_duration
  assume_role_policy   = data.aws_iam_policy_document.assume_role.json
  tags                 = var.tags
}

# -----------------------------------------------------------------------------
# Detect if the OIDC provider exists by probing
# -----------------------------------------------------------------------------
data "external" "oidc_provider_probe" {
  program = [
    "bash", "-c", <<-EOT
      set -euo pipefail
      PROVIDER_ARN=$(aws iam list-open-id-connect-providers --query 'OpenIDConnectProviderList[].Arn' --output text)
      for ARN in $PROVIDER_ARN; do
        URL=$(aws iam get-open-id-connect-provider --open-id-connect-provider-arn "$ARN" --query 'Url' --output text)
        if [ "$URL" = "https://token.actions.githubusercontent.com" ]; then
          echo "{\"arn\":\"$ARN\"}"
          exit 0
        fi
      done
      echo "{\"arn\":\"\"}"
    EOT
  ]
}

# -----------------------------------------------------------------------------
# Detect if the IAM role exists by probing
# -----------------------------------------------------------------------------
data "external" "oidc_role_probe" {
  program = [
    "bash", "-c", <<-EOT
      set -euo pipefail
      ROLE_NAME="${var.role_name}"
      ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text 2>/dev/null || echo "null")
      if [ "$ROLE_ARN" != "None" ] && [ "$ROLE_ARN" != "null" ]; then
        echo "{\"arn\":\"$ROLE_ARN\"}"
      else
        echo "{\"arn\":\"\"}"
      fi
    EOT
  ]
}
