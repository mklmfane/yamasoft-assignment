# Effective ARNs (created or existing)
locals {
  effective_backend_rw_arn = local.create_backend_rw ? aws_iam_policy.tf_backend_rw[0].arn : var.existing_backend_rw_policy_arn
  effective_vpc_apply_arn  = local.create_vpc_apply  ? aws_iam_policy.tf_vpc_apply[0].arn  : var.existing_vpc_apply_policy_arn
}

output "tf_backend_rw_policy_arn" {
  value       = local.effective_backend_rw_arn
  description = "ARN of the Terraform backend RW policy (created or existing)."
}

output "tf_vpc_apply_policy_arn" {
  value       = local.effective_vpc_apply_arn
  description = "ARN of the Terraform VPC apply policy (created or existing)."
}
