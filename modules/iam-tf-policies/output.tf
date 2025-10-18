# Output the ARN of the backend read-write policy
output "tf_backend_rw_policy_arn" {
  value       = length(var.existing_backend_rw_policy_arn) > 0 ? var.existing_backend_rw_policy_arn : aws_iam_policy.tf_backend_rw[0].arn
  description = "ARN of the Terraform backend RW policy (created or existing)."
}

# Output the ARN of the VPC apply policy
output "tf_vpc_apply_policy_arn" {
  value       = length(var.existing_vpc_apply_policy_arn) > 0 ? var.existing_vpc_apply_policy_arn : aws_iam_policy.tf_vpc_apply[0].arn
  description = "ARN of the Terraform VPC apply policy (created or existing)."
}
