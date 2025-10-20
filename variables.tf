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

#variable oidc_provider_content {
#  description = "OIDC provider for the personal github repositories"
#  default     = "token.actions.githubusercontent.com"
#}