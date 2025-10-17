// modules/github-oidc-role/variables.tf
variable "role_name" {
  description = "Name of the IAM role assumed by GitHub Actions"
  type        = string
}

variable "policy_arns" {
  description = "Managed policy ARNs to attach to the role (e.g., read-only or TF backend)"
  type        = list(string)
  default     = []
}

variable "inline_policies" {
  description = "Inline IAM policies to attach (map name => JSON policy)"
  type        = map(string)
  default     = {}
}

variable "subjects" {
  description = <<EOT
List of allowed GitHub OIDC 'sub' values. Use exact values like:
  - repo:ORG/REPO:ref:refs/heads/main
  - repo:ORG/REPO:environment:prod
Wildcards are allowed (e.g., repo:ORG/REPO:ref:refs/heads/release/*) and will be enforced with StringLike.
EOT
  type = list(string)
}

variable "audience" {
  description = "OIDC audience expected from GitHub. Use 'sts.amazonaws.com' with aws-actions/configure-aws-credentials."
  type        = string
  default     = "sts.amazonaws.com"
}

variable "provider_url" {
  description = "GitHub OIDC issuer URL"
  type        = string
  default     = "https://token.actions.githubusercontent.com"
}

variable "thumbprint_list" {
  description = <<EOT
Optional CA thumbprints for the OIDC provider. Leave null for modern AWS+GitHub OIDC (no pinning required).
Only set if your org mandates explicit thumbprints.
EOT
  type    = list(string)
  default = null
}

variable "tags" {
  description = "Tags to add on created resources"
  type        = map(string)
  default     = {}
}
perl
Copy code
:contentReference[oaicite:0]{index=0}:contentReference[oaicite:1]{index=1}:contentReference[oaicite:2]{index=2}:contentReference[oaicite:3]{index=3}
::contentReference[oaicite:4]{index=4}
hcl
Copy code
// modules/github-oidc-role/outputs.tf
output "role_arn" {
  description = "ARN of the IAM role assumed by GitHub Actions"
  value       = aws_iam_role.this.arn
}

output "oidc_provider_arn" {
  description = "ARN of the IAM OIDC provider for GitHub"
  value       = local.oidc_provider_arn
}