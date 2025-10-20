data "aws_caller_identity" "current" {}

locals {
  bucket_arn       = "arn:aws:s3:::${var.bucket_name}"
  bucket_objects   = "arn:aws:s3:::${var.bucket_name}/*"
  dynamodb_tbl_arn = "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${var.lock_table_name}"
}

# -----------------------------------------------------------------------------
# IAM Policy: create only when we couldn't detect an existing one
# -----------------------------------------------------------------------------
resource "aws_iam_policy" "tf_backend_rw" {
  count = length(trimspace(var.existing_backend_rw_policy_arn)) > 0 ? 0 : 1

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
        Sid      = "DynamoDBLocking,
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
      },
      {
        Sid      = "IamCreationPolicy", 
        Effect = "Allow",
        Action = [
          "iam:CreatePolicy",
          "iam:GetPolicy",
          "iam:ListPolicies",
          "iam:CreatePolicyVersion",
          "iam:DeletePolicyVersion",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "tf_vpc_apply" {
  count = length(trimspace(var.existing_vpc_apply_policy_arn)) > 0 ? 0 : 1

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