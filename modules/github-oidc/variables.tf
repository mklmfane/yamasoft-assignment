variable "create_oidc_provider" {
  description = "Whether to create the OIDC provider (auto-disabled if one matching the URL already exists)."
  type        = bool
  default     = true
}

variable "oidc_provider_arn" {
  description = "If you already have a provider, set its ARN to force using it."
  type        = string
  default     = ""
}

variable "create_oidc_role" {
  description = "Whether to create the OIDC role (auto-disabled if a role with the same name already exists)."
  type        = bool
  default     = true
}

variable "github_thumbprint" {
  description = "GitHub OpenID TLS certificate thumbprint."
  type        = string
  default     = "6938fd4d98bab03faadb97b34396831e3780aea1"
}

variable "repositories" {
  description = "List of GitHub org/repo names allowed to assume the role."
  type        = list(string)
  default     = []
  validation {
    condition = length([
      for repo in var.repositories : 1
      if length(regexall("^[A-Za-z0-9_.-]+?/([A-Za-z0-9_.:/-]+|\\*)$", repo)) > 0
    ]) == length(var.repositories)
    error_message = "Repositories must be in organization/repository format."
  }
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

variable "oidc_role_attach_policies" {
  description = "Policy ARNs to attach to the OIDC role."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags for created resources."
  type        = map(string)
  default     = {}
}

variable "role_name" {
  description = "Friendly name of the role (used to probe existence)."
  type        = string
  default     = "github-oidc-provider-aws"
}

variable "role_description" {
  description = "Description of the role."
  type        = string
  default     = "Role assumed by the GitHub OIDC provider."
}
