############################
# variables.tf
############################
variable "bucket_prefix_name" {
  description = "bucket prefix"
  type        = string
  default     = "tf-state-s3-bucket"
}

variable "lock_table" {
  description = "dynamodb lock table name (leave empty to skip creating)"
  type        = string
  default     = ""
}

# Toggle to actually create the bucket from this module.
# If the bucket already exists, set this to false and (optionally) import it.
variable "create_bucket" {
  description = "Create the S3 bucket from this module"
  type        = bool
  default     = true
}

# Toggle to actually create the lock table from this module.
# If the table already exists, set this false and (optionally) import it.
variable "create_lock_table" {
  description = "Create the DynamoDB table for state locking"
  type        = bool
  default     = true
}

variables "state_key" {
  description = "Terraform state key name"
  type = string
}

variable "existing_lock_table"  { 
  description = "The name of existing dynamodb table lock "
  type = string 
  default = "" 
}

variable "existing_bucket_name" { 
  description = "The name of existing bucket"
  type = string 
  default = "" 
}
