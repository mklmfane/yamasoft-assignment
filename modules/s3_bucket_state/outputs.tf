############################
# outputs.tf
############################
output "s3_bucket_id"     { 
  value = local.s3_bucket_id_effective     
}

output "lock_table_name"  { 
  value = local.lock_table_name_effective  
}

output "s3_bucket_id_output" {
  description = "Bucket name to use (created or existing)"
  value       = local.s3_bucket_id_effective
}

output "lock_table_name_output" {
  description = "DynamoDB lock table to use (created or existing)"
  value       = local.lock_table_name_effective
}

output "backend_key" { 
  value = local.backend_key_effective 
}