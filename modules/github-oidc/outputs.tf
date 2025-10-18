output "oidc_provider_arn" {
  description = "OIDC provider ARN"
  value       = try(aws_iam_openid_connect_provider.this[0].arn, "")
}

output "oidc_role" {
  description = "CICD GitHub role."
  value       = try(aws_iam_role.this[0].arn, "")
}

output "role_arn" {
  # When create_oidc_role = true -> index 0 exists; otherwise return null (or a var if you pass one)
  value = try(aws_iam_role.this[0].arn, null)
}