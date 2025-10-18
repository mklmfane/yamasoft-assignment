# Output the ARN of the backend read-write policy
output "tf_backend_rw_policy_arn" {
  value       = local.create_backend_rw ? aws_iam_policy.tf_backend_rw[0].arn : var.existing_backend_rw_policy_arn
  description = "ARN of the Terraform backend RW policy (created or existing)."
}

# Output the ARN of the VPC apply policy
output "tf_vpc_apply_policy_arn" {
  value       = local.create_vpc_apply ? aws_iam_policy.tf_vpc_apply[0].arn : var.existing_vpc_apply_policy_arn
  description = "ARN of the Terraform VPC apply policy (created or existing)."
}
