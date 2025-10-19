variable "bucket_prefix_name" {
  description = "bucket prefix"
  type        = string    
}

variable "lock_table" {
  description = "dynamodb lock table"
  type        = string   
  default     = "" 
}
