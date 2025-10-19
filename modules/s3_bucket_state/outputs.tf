############################
# outputs.tf
############################
output "s3_bucket_id" {
  description = "S3 bucket id created for terraform state file"
  value       = try(one(aws_s3_bucket.tf_state[*].id), null)
}

output "lock_table_name" {
  description = "Name of the DynamoDB state lock table created by this module (if any)."
  value       = try(one(aws_dynamodb_table.tf_locks[*].name), null)
}


output "s3_bucket_id_output" {
  description = "Bucket name to use (created or existing)"
  value       = local.s3_bucket_id_effective
}

output "lock_table_name_output" {
  description = "DynamoDB lock table to use (created or existing)"
  value       = local.lock_table_name_effective
}

output "backend_key" {                      # <— expose the key for the backend
  description = "S3 object key to store Terraform state"
  value       = local.backend_key_effective
}