
# -----------------------
# Outputs unify created vs existing ARNs
# -----------------------
# outputs.tf
output "tf_backend_rw_policy_arn" {
  description = "ARN of the Terraform backend RW policy (existing or created)."
  value       = local.create_backend_rw ? aws_iam_policy.tf_backend_rw[0].arn : var.existing_backend_rw_policy_arn
}

output "tf_vpc_apply_policy_arn" {
  description = "ARN of the Terraform VPC apply policy (existing or created)."
  value       = local.create_vpc_apply ? aws_iam_policy.tf_vpc_apply[0].arn : var.existing_vpc_apply_policy_arn
}