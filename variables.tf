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