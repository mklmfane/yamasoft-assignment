output "tf_state_bucket_name" {
  value       = module.s3-bucket-state-oidc.s3_bucket_id
  description = "Name of the S3 bucket used for Terraform state."
}

output "tf_lock_table_name" {
  value       =  module.s3-bucket-state-oidc.lock_table_name
  description = "Name of the DynamoDB table used for Terraform state locking."
}

output "github_oidc_role_arn" {
  description = "ARN of the GitHub OIDC role (created by module or provided)."
  value       = try(module.github-oidc.role_arn, null)
}