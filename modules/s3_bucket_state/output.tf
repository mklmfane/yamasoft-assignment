
output "s3_bucket_id" {
  description = "S3 bucket id created for terraform state file"
  value       = aws_s3_bucket.tf_state.id
}

output "lock_table_name" {
  description = "Dynamodb lock table"
  value       = aws_dynamodb_table.tf_locks[0].name
}
