variable "environment" {
  description = "Chosen environment"
  type  = string
  default = "dev"
}

variable "vpc_name" {
  description = "The vpc name"
  type        = string
}

variable "repository_list" {
  description = "List of repositories"
  type        = list(string)
}

variable "bucket_prefix_name" {
  description = "bucket prefix name"
  type        = string
  default     = "tf-state-s3-bucket"     
}

variable "create_bucket" { 
  description = "Require to create s3 bucket"
  type = bool   
  default = true 
}

variable "existing_bucket_name" { 
  description = "The name of existing bucket"
  type = string 
  default = "" 
}

variable "create_lock_table" { 
  description = "Require to create dynamodb lock table"
  type = bool   
  default = true 
}

variable "existing_lock_table"  { 
  description = "The name of existing dynamodb table lock "
  type = string 
  default = "" 
}

variable "region" {
  description = "Region of provisoning resources"
  type        = string    
  default     = "eu-west-1"
}

variable "lock_table" {
  description = "lock table of dynamodb"
  type        = string
}

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