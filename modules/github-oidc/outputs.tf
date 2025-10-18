output "oidc_provider_arn" {
  description = "OIDC provider ARN (existing or created)."
  value = coalesce(
    try(aws_iam_openid_connect_provider.this[0].arn, null),
    try(data.external.oidc_provider_probe.result.arn, null),
    length(var.oidc_provider_arn) > 0 ? var.oidc_provider_arn : null
  )
}

output "oidc_role" {
  description = "OIDC role ARN (existing or created)."
  value = coalesce(
    try(aws_iam_role.this[0].arn, null),
    try(data.external.oidc_role_probe.result.arn, null)
  )
}

output "role_arn" {
  description = "Alias of oidc_role for convenience."
  value = coalesce(
    try(aws_iam_role.this[0].arn, null),
    try(data.external.oidc_role_probe.result.arn, null)
  )
}
