terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# Needed to build the DynamoDB ARN with the correct account id
data "aws_caller_identity" "current" {}

locals {
  bucket_arn       = "arn:aws:s3:::${var.bucket_name}"
  bucket_objects   = "arn:aws:s3:::${var.bucket_name}/*"
  dynamodb_tbl_arn = "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${var.lock_table_name}"

  # Did caller provide ARNs?
  provided_backend_rw = length(trimspace(var.existing_backend_rw_policy_arn)) > 0
  provided_vpc_apply  = length(trimspace(var.existing_vpc_apply_policy_arn))  > 0

  # Combine both checks for policy existence and creation
  provided_backend_rw_exists = local.provided_backend_rw ? (try(data.external.check_backend_rw[0].result.exists, "false") == "true") : false
  provided_vpc_apply_exists  = local.provided_vpc_apply ? (try(data.external.check_vpc_apply[0].result.exists, "false") == "true") : false

  create_backend_rw = !local.provided_backend_rw_exists
  create_vpc_apply  = !local.provided_vpc_apply_exists
}

# If an ARN was provided, check that it actually exists. (Requires AWS CLI)
data "external" "check_backend_rw" {
  count   = local.provided_backend_rw ? 1 : 0
  program = [
    "bash", "-c",
    "aws iam get-policy --policy-arn ${var.existing_backend_rw_policy_arn} >/dev/null 2>&1 && echo '{\"exists\":\"true\"}' || echo '{\"exists\":\"false\"}'"
  ]
}

data "external" "check_vpc_apply" {
  count   = local.provided_vpc_apply ? 1 : 0
  program = [
    "bash", "-c",
    "aws iam get-policy --policy-arn ${var.existing_vpc_apply_policy_arn} >/dev/null 2>&1 && echo '{\"exists\":\"true\"}' || echo '{\"exists\":\"false\"}'"
  ]
}

# Check if the backend policy exists
data "aws_iam_policy" "backend_rw" {
  count = length(var.existing_backend_rw_policy_arn) > 0 ? 1 : 0
  arn   = var.existing_backend_rw_policy_arn
}

# Check if the VPC apply policy exists
data "aws_iam_policy" "vpc_apply" {
  count = length(var.existing_vpc_apply_policy_arn) > 0 ? 1 : 0
  arn   = var.existing_vpc_apply_policy_arn
}

# Create the IAM policy for backend rw if it doesn't already exist
resource "aws_iam_policy" "tf_backend_rw" {
  count = local.create_backend_rw ? 1 : 0
  name  = var.policy_name_backend_rw
  tags  = var.tags

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "S3StateRW",
        Effect   = "Allow",
        Action   = ["s3:ListBucket","s3:GetObject","s3:PutObject","s3:DeleteObject"],
        Resource = [local.bucket_arn, local.bucket_objects]
      },
      {
        Sid      = "DynamoDBLocking",
        Effect   = "Allow",
        Action   = ["dynamodb:DescribeTable","dynamodb:GetItem","dynamodb:PutItem","dynamodb:DeleteItem"],
        Resource = local.dynamodb_tbl_arn
      }
    ]
  })
}

# Create the IAM policy for VPC apply if it doesn't already exist
resource "aws_iam_policy" "tf_vpc_apply" {
  count = local.create_vpc_apply ? 1 : 0
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
      },
      # Add other policy statements here as per your requirements...
    ]
  })
}

