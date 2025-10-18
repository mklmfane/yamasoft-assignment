variable "create_oidc_provider" {
  description = "Whether to create the OIDC provider (auto-disabled if one matching the URL already exists)."
  type        = bool
  default     = true
}

variable "create_oidc_role" {
  description = "Whether to create the OIDC role (auto-disabled if a role with the same name already exists)."
  type        = bool
  default     = true
}

variable "existing_oidc_provider_arn" {
  description = "ARN of an existing OIDC provider (if any)."
  type        = string
  default     = ""
}

variable "existing_role_arn" {
  description = "ARN of an existing IAM role (if any)."
  type        = string
  default     = ""
}

variable "oidc_role_attach_policies" {
  description = "Policy ARNs to attach to the OIDC role."
  type        = list(string)
  default     = []
}

variable "role_name" {
  description = "Friendly name of the role."
  type        = string
  default     = "github-oidc-provider-aws"
}

variable "role_description" {
  description = "Description of the role."
  type        = string
  default     = "Role assumed by the GitHub OIDC provider."
}

variable "repositories" {
  description = "List of GitHub repository names."
  type        = list(string)
  default     = []
}

variable "github_thumbprint" {
  description = "GitHub OpenID certificate thumbprint."
  type        = string
  default     = "6938fd4d98bab03faadb97b34396831e3780aea1"
}

variable "tags" {
  description = "Tags to assign to created resources."
  type        = map(string)
  default     = {}
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds."
  type        = number
  default     = 3600
  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "Maximum session duration must be between 3600 and 43200 seconds."
  }
}
