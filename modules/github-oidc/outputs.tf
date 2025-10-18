output "oidc_provider_arn" {
  description = "The ARN of the OIDC provider."
  value       = try(data.external.oidc_provider_probe.result.arn, null)
}

output "oidc_role" {
  description = "The ARN of the OIDC role."
  value       = try(data.external.oidc_role_probe.result.arn, null)
}

output "role_arn" {
  description = "The ARN of the IAM role."
  value       = try(data.external.oidc_role_probe.result.arn, null)
}
