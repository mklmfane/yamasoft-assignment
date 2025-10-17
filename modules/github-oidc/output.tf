// modules/github-oidc-role/outputs.tf
output "role_arn" {
  description = "ARN of the IAM role assumed by GitHub Actions"
  value       = aws_iam_role.this.arn
}

output "oidc_provider_arn" {
  description = "ARN of the IAM OIDC provider for GitHub"
  value       = local.oidc_provider_arn
}
