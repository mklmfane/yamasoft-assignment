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
