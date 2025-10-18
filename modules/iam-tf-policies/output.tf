output "tf_backend_rw_policy_arn" {
  description = "ARN of the Terraform backend RW policy."
  value       = aws_iam_policy.tf_backend_rw.arn
}

output "tf_vpc_apply_policy_arn" {
  description = "ARN of the Terraform VPC apply policy."
  value       = aws_iam_policy.tf_vpc_apply.arn
}