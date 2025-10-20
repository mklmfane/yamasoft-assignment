
output "s3_bucket_id" { 
  description = "S3 bucket id"
  value = module.s3_bucket_state_oidc.s3_bucket_id 
}

output "backend_key" { 
  description = "The backend key for locking terraform state file"
  value = module.s3_bucket_state_oidc.backend_key
}

output "lock_table_name" {
  value       = module.s3_bucket_state_oidc.lock_table_name
  description = "Name of the DynamoDB table used for Terraform state locking."
}

output "effective_role_arn" {
  description = "IAM role ARN for GitHub OIDC"
  value       = module.github_oidc.effective_role_arn
}


output "effective_oidc_provider_arn" {
  description = "OIDC provider ARN used by the GitHub OIDC role"
  value       = module.github_oidc.effective_oidc_provider_arn
}
