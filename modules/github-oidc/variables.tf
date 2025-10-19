variable "create_oidc_provider" {
  description = "Create the OIDC provider (skipped if one already exists for GitHub URL)."
  type        = bool
  default     = true
}

variable "create_oidc_role" {
  description = "Create the IAM role (skipped if a role with the same name already exists)."
  type        = bool
  default     = true
}

variable "existing_oidc_provider_arn" {
  description = "If set, use this existing OIDC provider ARN instead of creating one."
  type        = string
  default     = ""
}

variable "existing_role_arn" {
  description = "If set, use this existing IAM role ARN instead of creating one."
  type        = string
  default     = ""
}

variable "repositories" {
  description = "Allowed GitHub repos (org/repo or org/repo:ref) to assume the role."
  type        = list(string)
  default     = []
}

variable "oidc_role_attach_policies" {
  description = "Managed policy ARNs to attach to the role (only if we created the role)."
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

variable "max_session_duration" {
  description = "Maximum session duration in seconds."
  type        = number
  default     = 3600
}

variable "region" {
  description = "Optional region (not needed for OIDC creation)."
  type        = string
  default     = ""
}
