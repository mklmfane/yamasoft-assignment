
# -----------------------
# Outputs unify created vs existing ARNs
# -----------------------
output "tf_backend_rw_policy_arn" {
  description = "ARN of the Terraform backend RW policy (existing or created)."
  value       = local.policy_exists.tf_backend_rw ? local.existing_policy_arns.tf_backend_rw : aws_iam_policy.tf_backend_rw[0].arn
}

output "tf_vpc_apply_policy_arn" {
  description = "ARN of the Terraform VPC apply policy (existing or created)."
  value       = local.policy_exists.tf_vpc_apply ? local.existing_policy_arns.tf_vpc_apply : aws_iam_policy.tf_vpc_apply[0].arn
}
