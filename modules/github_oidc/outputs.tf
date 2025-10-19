# OIDC provider ARN used (created by this module OR the one you passed in)
output "effective_oidc_provider_arn" {
  description = "OIDC provider ARN used by the role trust policy."
  value = var.create_oidc_provider
    ? try(aws_iam_openid_connect_provider.this[0].arn, "")
    : (var.oidc_provider_arn != null ? var.oidc_provider_arn : "")
}

# IAM role ARN (created by this module, or empty string if not created)
output "effective_role_arn" {
  description = "IAM role ARN created by this module (empty if create_oidc_role=false)."
  value       = try(aws_iam_role.this[0].arn, "")
}
