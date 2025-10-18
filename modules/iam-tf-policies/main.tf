terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# Needed to build the DynamoDB ARN with correct account id
data "aws_caller_identity" "current" {}

locals {
  bucket_arn       = "arn:aws:s3:::${var.bucket_name}"
  bucket_objects   = "arn:aws:s3:::${var.bucket_name}/*"
  dynamodb_tbl_arn = "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${var.lock_table_name}"


  create_backend_rw = var.existing_backend_rw_policy_arn == ""
  create_vpc_apply  = var.existing_vpc_apply_policy_arn == ""

  policy_names = {
    tf_backend_rw = var.policy_name_backend_rw
    tf_vpc_apply  = var.policy_name_vpc_apply
  }
}


# -----------------------
# Probe existing policies by name (via AWS CLI)
# Requires AWS CLI on runner + credentials in env.
# -----------------------
data "external" "policy_probe" {
  for_each = local.policy_names

  program = [
    "bash", "-c", <<-EOT
      set -euo pipefail
      NAME='${each.value}'
      # Try to find a customer-managed policy with this name
      ARN=$(aws iam list-policies \
        --scope Local \
        --query "Policies[?PolicyName=='${each.value}'].Arn | [0]" \
        --output text 2>/dev/null || echo 'None')

      if [ "$ARN" = "None" ] || [ -z "$ARN" ] || [ "$ARN" = "null" ]; then
        echo '{"exists":"false"}'
      else
        # IMPORTANT: escape Terraform interpolation with $$
        echo "{\"exists\":\"true\",\"arn\":\"$${ARN}\"}"
      fi
    EOT
  ]
}

locals {
  policy_exists = {
    for k, v in data.external.policy_probe :
    k => try(v.result.exists, "false") == "true"
  }

  existing_policy_arns = {
    for k, v in data.external.policy_probe :
    k => try(v.result.arn, "")
  }
}


resource "aws_iam_policy" "tf_backend_rw" {

  count = local.create_backend_rw ? 1 : 0

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
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ],
        Resource = local.dynamodb_tbl_arn
      }
    ]
  })
}

resource "aws_iam_policy" "tf_vpc_apply" {
   count = local.create_vpc_apply ? 1 : 0

  name = var.policy_name_vpc_apply
  tags = var.tags

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { 
        Sid = "EC2Describe", 
        Effect = "Allow", 
        Action = [
          "ec2:Describe*",
          "ec2:Get*"], 
        Resource = "*"
      },
      { 
        Sid = "VpcCore",     
        Effect = "Allow", 
        Action = [
          "ec2:CreateVpc",
          "ec2:DeleteVpc",
          "ec2:ModifyVpcAttribute",
          "ec2:CreateSubnet",
          "ec2:DeleteSubnet",
          "ec2:ModifySubnetAttribute",
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ], 
        Resource = "*" 
      },
      { 
        Sid = "IGW",         
        Effect = "Allow", 
        Action = [
          "ec2:CreateInternetGateway",
          "ec2:DeleteInternetGateway",
          "ec2:AttachInternetGateway",
          "ec2:DetachInternetGateway"
        ], 
        Resource = "*" 
      },
      { 
        Sid = "Routes",      
        Effect = "Allow", 
        Action = [
          "ec2:CreateRouteTable",
          "ec2:DeleteRouteTable",
          "ec2:CreateRoute",
          "ec2:ReplaceRoute",
          "ec2:DeleteRoute",
          "ec2:AssociateRouteTable",
          "ec2:DisassociateRouteTable",
          "ec2:ReplaceRouteTableAssociation"
        ], 
        Resource = "*" 
      },
      { 
        Sid = "NatAndEip",   
        Effect = "Allow", 
        Action = [
          "ec2:AllocateAddress",
          "ec2:ReleaseAddress",
          "ec2:CreateNatGateway",
          "ec2:DeleteNatGateway",
          "ec2:TagResources",
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ], 
        Resource = "*" 
      },
      { 
        Sid = "DefaultSGRules", 
        Effect = "Allow", 
        Action = [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:UpdateSecurityGroupRuleDescriptionsIngress",
          "ec2:UpdateSecurityGroupRuleDescriptionsEgress"
        ], 
        Resource = "*" 
      },
      { 
        Sid = "DefaultNaclEntries", 
        Effect = "Allow", 
        Action = [
          "ec2:CreateNetworkAclEntry",
          "ec2:DeleteNetworkAclEntry",
          "ec2:ReplaceNetworkAclEntry",
          "ec2:ReplaceNetworkAclAssociation"
        ], 
        Resource = "*" 
      },
      { 
        Sid = "VpcEndpoints", 
        Effect = "Allow", 
        Action = [
          "ec2:CreateVpcEndpoint",
          "ec2:ModifyVpcEndpoint",
          "ec2:DeleteVpcEndpoints"
        ], 
        Resource = "*" 
      },
      { 
        Sid = "ELBAndSSMDescribe", 
        Effect = "Allow", 
        Action = [
          "elasticloadbalancing:Describe*",
          "ssm:Describe*",
          "ssm:Get*",
          "ssm:List*"
        ], 
        Resource = "*"
      }
    ]
  })
}
