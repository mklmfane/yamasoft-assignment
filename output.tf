output "tf_state_bucket_name" {
  value       = module.s3-bucket-state-oidc.s3_bucket_id
  description = "Name of the S3 bucket used for Terraform state."
}

output "tf_lock_table_name" {
  value       =  module.s3-bucket-state-oidc.lock_table_name
  description = "Name of the DynamoDB table used for Terraform state locking."
}

# forward the module output under the exact name your workflow expects
output "github_oidc_role_arn" {
  description = "IAM role ARN used by GitHub OIDC."
  value = length(try(module.github-oidc.effective_role_arn, "")) > 0
    ? module.github-oidc.effective_role_arn
    : ""
}