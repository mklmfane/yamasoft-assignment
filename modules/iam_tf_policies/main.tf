data "aws_caller_identity" "current" {}

locals {
  bucket_arn       = "arn:aws:s3:::${var.bucket_name}"
  bucket_objects   = "arn:aws:s3:::${var.bucket_name}/*"
  dynamodb_tbl_arn = "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${var.lock_table_name}"
}

# --- Probes (safe with missing perms; won't break plan) ---
#data "external" "backend_rw_probe" {
#  program = [
#    "bash", "-c", <<-EOT
#      set -euo pipefail
#      NAME="${var.policy_name_backend_rw}"
#      ARN=$(aws iam list-policies --scope Local \
#            --query "Policies[?PolicyName=='$${NAME}'].Arn | [0]" \
#            --output text 2>/dev/null || echo "")
#      if [ "$ARN" = "None" ] || [ "$ARN" = "null" ]; then ARN=""; fi
#      echo "{\"arn\":\"$ARN\"}"
#    EOT
#  ]
#}

#data "external" "vpc_apply_probe" {
#  program = [
#    "bash", "-c", <<-EOT
#      set -euo pipefail
#      NAME="${var.policy_name_vpc_apply}"
#      ARN=$(aws iam list-policies --scope Local \
#            --query "Policies[?PolicyName=='$${NAME}'].Arn | [0]" \
#            --output text 2>/dev/null || echo "")
#      if [ "$ARN" = "None" ] || [ "$ARN" = "null" ]; then ARN=""; fi
#      echo "{\"arn\":\"$ARN\"}"
#    EOT
#  ]
#}

#locals {
  # Decide the "existing" ARNs: prefer explicit inputs; else probe results; else ""
#  existing_backend_rw_arn = (
#    length(trimspace(var.existing_backend_rw_policy_arn)) > 0
#    ? trimspace(var.existing_backend_rw_policy_arn)
#    : trimspace(try(data.external.backend_rw_probe.result.arn, ""))
#  )

#  existing_vpc_apply_arn = (
#    length(trimspace(var.existing_vpc_apply_policy_arn)) > 0
#    ? trimspace(var.existing_vpc_apply_policy_arn)
#    : trimspace(try(data.external.vpc_apply_probe.result.arn, ""))
#  )
#}

# -----------------------------------------------------------------------------
# IAM Policy: create only when we couldn't detect an existing one
# -----------------------------------------------------------------------------
resource "aws_iam_policy" "tf_backend_rw" {
  count = length(trimspace(var.existing_backend_rw_policy_arn)) > 0 ? 0 : 1

  #count = length(local.existing_backend_rw_arn) > 0 ? 0 : 1
  name = var.policy_name_backend_rw
  tags = var.tags

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "S3StateRW",
        Effect   = "Allow",
        Action   = [
          "s3:ListBucket", 
          "s3:CreateBucket",
          "s3:GetObject", 
          "s3:PutObject", 
          "s3:DeleteObject"
        ],
        Resource = [
          local.bucket_arn, 
          local.bucket_objects
        ]
      },
      {
        Sid      = "DynamoDBLocking",
        Effect   = "Allow",
        Action   = [
          "dynamodb:DescribeTable", 
          "dynamodb:GetItem",
          "dynamodb:CreateTable",  
          "dynamodb:PutItem", 
          "dynamodb:DeleteItem",
          "dynamodb:TagResource"
        ],
        Resource = [
          local.dynamodb_tbl_arn
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "tf_vpc_apply" {
  count = length(trimspace(var.existing_vpc_apply_policy_arn)) > 0 ? 0 : 1

  #count = length(local.existing_vpc_apply_arn) > 0 ? 0 : 1
  name = var.policy_name_vpc_apply
  tags = var.tags

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "EC2Describe",
        Effect   = "Allow",
        Action   = [
          "ec2:Describe*", 
          "ec2:Get*",
          "ec2:CreateTags",
          "ec2:CreateVpc"
        ],
        Resource = "*"
      }
    ]
  })
}