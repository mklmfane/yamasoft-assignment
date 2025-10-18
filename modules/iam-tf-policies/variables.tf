variable "bucket_name" {
  description = "Existing S3 bucket name that stores Terraform state."
  type        = string
}

variable "lock_table_name" {
  description = "Existing DynamoDB table name used for state locking."
  type        = string
}

variable "region" {
  description = "AWS region where the DynamoDB lock table lives."
  type        = string
}

variable "policy_name_backend_rw" {
  description = "Name for the S3/DynamoDB RW policy."
  type        = string
  default     = "tf-backend-rw"
}

variable "policy_name_vpc_apply" {
  description = "Name for the VPC apply policy."
  type        = string
  default     = "tf-vpc-apply"
}

variable "tags" {
  description = "Tags applied to created IAM policies."
  type        = map(string)
  default     = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# Optionally provide the ARNs for existing policies to skip creation
variable "existing_backend_rw_policy_arn" {
  description = "If set, skip creating tf-backend-rw and use this ARN."
  type        = string
  default     = ""
}

variable "existing_vpc_apply_policy_arn" {
  description = "If set, skip creating tf-vpc-apply and use this ARN."
  type        = string
  default     = ""
}
