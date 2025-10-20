variable "create_oidc_provider" {
  description = "Whether to create the OIDC provider. If false, provide oidc_provider_arn."
  type        = bool
  default     = true
}

variable "oidc_provider_arn" {
  description = "Existing OIDC provider ARN to use (required if create_oidc_provider=false)."
  type        = string
  default     = ""
}

variable "create_oidc_role" {
  description = "Whether to create the IAM role for GitHub OIDC."
  type        = bool
  default     = true
}

variable "oidc_provider_arn" {
  description = "Existing OIDC provider ARN to use."
  type        = string
  default     = ""
}

variable "repositories" {
  description = "Allowed GitHub repos (org/repo or org/repo:ref) to assume the role."
  type        = list(string)
  default     = []
}

variable "oidc_role_attach_policies" {
  description = "Managed policy ARNs to attach to the created role."
  type        = list(string)
  default     = []
}

variable "role_name" {
  description = "Name of the IAM role."
  type        = string
  default     = "github-oidc-provider-aws"
}

variable "role_description" {
  description = "Description of the IAM role."
  type        = string
  default     = "Role assumed by the GitHub OIDC provider."
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds."
  type        = number
  default     = 3600
}

variable "github_thumbprint" {
  description = "GitHub OIDC root CA thumbprint."
  type        = string
  default     = "6938fd4d98bab03faadb97b34396831e3780aea1"
}

variable "tags" {
  description = "Tags for created resources."
  type        = map(string)
  default     = {}
}
