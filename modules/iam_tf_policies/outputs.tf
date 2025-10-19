output "tf_backend_rw_policy_arn" {
  description = "ARN of the Terraform backend RW policy (created or existing)."
  value = (
    length(trimspace(local.existing_backend_rw_arn)) > 0
    ? local.existing_backend_rw_arn
    : aws_iam_policy.tf_backend_rw[0].arn
  )
}

output "tf_vpc_apply_policy_arn" {
  description = "ARN of the Terraform VPC apply policy (created or existing)."
  value = (
    length(trimspace(local.existing_vpc_apply_arn)) > 0
    ? local.existing_vpc_apply_arn
    : aws_iam_policy.tf_vpc_apply[0].arn
  )
}
