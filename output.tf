output "tf_state_bucket_name" {
  value       = module.s3_bucket_state_oidc.s3_bucket_id
  description = "Name of the S3 bucket used for Terraform state."
}

output "tf_lock_table_name" {
  value       = module.s3_bucket_state_oidc.lock_table_name
  description = "Name of the DynamoDB table used for Terraform state locking."
}


output "github_oidc_role_arn" {
  description = "IAM role ARN used by GitHub OIDC."
  value       = length(try(module.github_oidc.effective_role_arn, "")) > 0 ? module.github_oidc.effective_role_arn : ""
}

output "s3_bucket_id" { 
  value = module.s3_bucket_state_oidc.s3_bucket_id 
}

output "backend_key" { 
  value = module.s3_bucket_state_oidc.lock_table_name 
}

output "effective_role_arn" { 
  value = module.github_oidc.effective_role_arn
}