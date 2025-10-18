output "oidc_provider_arn" {
  value = coalesce(
    try(aws_iam_openid_connect_provider.this[0].arn, null),
    length(var.existing_oidc_provider_arn) > 0 ? var.existing_oidc_provider_arn : null,
    length(var.oidc_provider_arn) > 0 ? var.oidc_provider_arn : null
  )
}

output "role_arn" {
  value = coalesce(
    try(aws_iam_role.this[0].arn, null),
    length(var.existing_role_arn) > 0 ? var.existing_role_arn : null
  )
}
