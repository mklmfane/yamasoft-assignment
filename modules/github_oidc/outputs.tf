# modules/github-oidc/outputs.tf

# What provider ARN the role trusts (created → input → probe → "")
output "effective_oidc_provider_arn" {
  description = "OIDC provider ARN used by the role trust policy (created, input, or discovered)."
  value       = local.federated_provider_arn
}

# Role ARN (created → input → probe → "")
output "effective_role_arn" {
  description = "IAM role ARN (created by module, provided via input, or discovered)."
  value = length(try(aws_iam_role.this[0].arn, "")) > 0 ? aws_iam_role.this[0].arn 
    : (length(trimspace(var.existing_role_arn)) > 0 ? 
      trimspace(var.existing_role_arn) : trimspace(try(data.external.oidc_role_probe.result.arn, "")))
}

#output "effective_role_arn" {
#  description = "IAM role ARN (created, provided, or discovered)."
#  value = length(try(aws_iam_role.this[0].arn, "")) > 0
#    ? aws_iam_role.this[0].arn
#    : (
#        length(trimspace(var.existing_role_arn)) > 0
#        ? trimspace(var.existing_role_arn)
#        : trimspace(try(data.external.oidc_role_probe.result.arn, ""))
#      )
#}


# Optional: expose whether we attempted to create things (purely from inputs)
output "create_provider" {
  description = "Whether the module was set (by inputs) to create the OIDC provider."
  value       = local.create_provider
}

output "create_role" {
  description = "Whether the module was set (by inputs) to create the IAM role."
  value       = local.create_role_gate
}

