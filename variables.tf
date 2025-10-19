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

variable "region" {
  description = "Region of provisoning resources"
  type        = string    
  default     = "eu-west-1"
}

variable "lock_table" {
  description = "lock table of dynamodb"
  type        = string
}

variable oidc_provider_content {
  description = "OIDC provider for the personal github repositories"
  default     = "token.actions.githubusercontent.com"
}