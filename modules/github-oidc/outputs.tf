
# -----------------------------------------------------------------------------
# Output the OIDC provider ARN and role ARN
# -----------------------------------------------------------------------------
output "oidc_provider_arn" {
  value       = try(data.external.oidc_provider_probe.result.arn, null)
  description = "The ARN of the OIDC provider."
}

output "oidc_role_arn" {
  value       = try(data.external.oidc_role_probe.result.arn, null)
  description = "The ARN of the OIDC role."
}
