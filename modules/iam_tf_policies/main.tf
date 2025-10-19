terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# Required data for DynamoDB and S3
data "aws_caller_identity" "current" {}

locals {
  # Dynamically build the ARNs for the S3 bucket and DynamoDB table
  bucket_arn       = "arn:aws:s3:::${var.bucket_name}"
  bucket_objects   = "arn:aws:s3:::${var.bucket_name}/*"
  dynamodb_tbl_arn = "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${var.lock_table_name}"
}

# -----------------------------------------------------------------------------
# IAM Policy: Check if the policy exists and create if not
# -----------------------------------------------------------------------------
resource "aws_iam_policy" "tf_backend_rw" {
  count = var.existing_backend_rw_policy_arn != "" ? 0 : 1

  name  = var.policy_name_backend_rw
  tags  = var.tags

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "S3StateRW",
        Effect   = "Allow",
        Action   = ["s3:ListBucket", "s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
        Resource = [local.bucket_arn, local.bucket_objects]
      },
      {
        Sid      = "DynamoDBLocking",
        Effect   = "Allow",
        Action   = ["dynamodb:DescribeTable", "dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"],
        Resource = local.dynamodb_tbl_arn
      }
    ]
  })
}

resource "aws_iam_policy" "tf_vpc_apply" {
  count = var.existing_vpc_apply_policy_arn != "" ? 0 : 1

  name  = var.policy_name_vpc_apply
  tags  = var.tags

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "EC2Describe",
        Effect = "Allow",
        Action = ["ec2:Describe*", "ec2:Get*"],
        Resource = "*"
      }
    ]
  })
}