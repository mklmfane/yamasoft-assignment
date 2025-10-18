variable "bucket_suffix_name" {
  description = "bucket suffix"
  type        = string    
}

variable "lock_table" {
  description = "dynamodb lock table"
  type        = string   
  default     = "" 
}

variable "create_lock_table" {
  type    = bool
  default = false
}