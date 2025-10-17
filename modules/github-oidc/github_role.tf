# terraform/aws/github_role.tf
data "aws_caller_identity" "current" {}

# Replace ORG and REPO and branch/env to match your setup
locals {
  github_org   = "ORG"
  github_repo  = "REPO"
  github_ref   = "ref:refs/heads/main"     # OR use: "environment:prod"
}

resource "aws_iam_role" "github_actions" {
  name               = "github-actions-terraform"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          # REQUIRED by AWS now: restrict by 'sub' so only your repo/branch (or env) can assume
          # Branch example:
          "token.actions.githubusercontent.com:sub" = "repo:${local.github_org}/${local.github_repo}:${local.github_ref}"
          # If you use GitHub Environments instead of branch, use:
          # "token.actions.githubusercontent.com:sub" = "repo:${local.github_org}/${local.github_repo}:environment:prod"
        }
      }
    }]
  })
}

# Give the role only what Terraform needs. Example:
# - Access to your remote state S3 bucket and DynamoDB lock table
# - Read-only "Describe/List" to plan safely (tighten as needed)
resource "aws_iam_policy" "tf_plan_minimum" {
  name   = "tf-plan-minimum"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "StateBackend"
        Effect = "Allow"
        Action = ["s3:*"]
        Resource = [
          "arn:aws:s3:::my-tf-state-bucket",
          "arn:aws:s3:::my-tf-state-bucket/*"
        ]
      },
      {
        Sid      = "DynamoLock"
        Effect   = "Allow"
        Action   = ["dynamodb:*"]
        Resource = "arn:aws:dynamodb:eu-central-1:${data.aws_caller_identity.current.account_id}:table/tf-locks"
      },
      {
        Sid    = "ReadOnlyDescribe"
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "iam:Get*","iam:List*",
          "eks:Describe*","eks:List*",
          "rds:Describe*","rds:List*",
          "elasticloadbalancing:Describe*",
          "cloudformation:Describe*","cloudformation:List*",
          "ssm:Describe*","ssm:Get*","ssm:List*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_tf_plan_minimum" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.tf_plan_minimum.arn
}
