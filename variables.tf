variable "vpc_name" {
  description = "The vpc name"
  type        = string
}

variable "repository_list" {
  description = "List of repositories"
  type        = list(string)
}

variable "bucket_suffix_name" {
  description = "bucket suffix"
  type        = string    
}

variable "region" {
  description = "Region of provisoning resources"
  type        = string    
  default     = "eu-ewest-1"
}

variable "lock_table" {
  description = "lock table of dynamodb"
  type        = string
}

variable "oidc_provider_arn" { 
  description = "check existance of oidc provider arn"
  type = string
  default = "" 
}

variable "existing_role_arn" { 
  description = "check existance of the role arn"
  type = string 
  default = "" 
}

variable oidc_provider_content {
  description = "OIDC provider for the personal github repositories"
  default     = "token.actions.githubusercontent.com"
}