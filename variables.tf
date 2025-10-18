variable "vpc_name" {
  description = "The vpc name"
  type        = string
}

variable "repository_list" {
  description = "List of repositories"
  type        = list(string)
}