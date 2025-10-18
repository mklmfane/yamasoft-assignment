data "aws_caller_identity" "current" {}

locals {
  state_bucket = "my-tf-state-bucket--xxxxxx"
  lock_table   = "tf-locks"
  region       = "eu-west-1"
}

resource "aws_iam_policy" "tf_backend_rw" {
  name = "tf-backend-rw"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid: "S3StateRW",
        Effect: "Allow",
        Action: [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        Resource: [
          "arn:aws:s3:::${local.state_bucket}",
          "arn:aws:s3:::${local.state_bucket}/*"
        ]
      },
      {
        Sid: "DynamoDBLocking",
        Effect: "Allow",
        Action: [
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ],
        Resource: "arn:aws:dynamodb:${local.region}:${data.aws_caller_identity.current.account_id}:table/${local.lock_table}"
      }
    ]
  })
}

resource "aws_iam_policy" "tf_vpc_apply" {
  name = "tf-vpc-apply"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # Broad describes so Terraform can read current state
      {
        Sid: "EC2Describe",
        Effect: "Allow",
        Action: [
          "ec2:Describe*",
          "ec2:Get*"
        ],
        Resource: "*"
      },

      # VPC + Subnets
      {
        Sid: "VpcCore",
        Effect: "Allow",
        Action: [
          "ec2:CreateVpc", "ec2:DeleteVpc", "ec2:ModifyVpcAttribute",
          "ec2:CreateSubnet", "ec2:DeleteSubnet", "ec2:ModifySubnetAttribute",
          "ec2:CreateTags", "ec2:DeleteTags"
        ],
        Resource: "*"
      },

      # Internet Gateway
      {
        Sid: "IGW",
        Effect: "Allow",
        Action: [
          "ec2:CreateInternetGateway", "ec2:DeleteInternetGateway",
          "ec2:AttachInternetGateway", "ec2:DetachInternetGateway"
        ],
        Resource: "*"
      },

      # Route tables + routes + associations
      {
        Sid: "Routes",
        Effect: "Allow",
        Action: [
          "ec2:CreateRouteTable", "ec2:DeleteRouteTable",
          "ec2:CreateRoute", "ec2:ReplaceRoute", "ec2:DeleteRoute",
          "ec2:AssociateRouteTable", "ec2:DisassociateRouteTable",
          "ec2:ReplaceRouteTableAssociation"
        ],
        Resource: "*"
      },

      # NAT Gateway + EIPs
      {
        Sid: "NatAndEip",
        Effect: "Allow",
        Action: [
          "ec2:AllocateAddress", "ec2:ReleaseAddress",
          "ec2:CreateNatGateway", "ec2:DeleteNatGateway",
          "ec2:TagResources", "ec2:CreateTags", "ec2:DeleteTags"
        ],
        Resource: "*"
      },

      # Default Security Group rule management
      # (the aws_default_security_group resource revokes/adds rules)
      {
        Sid: "DefaultSGRules",
        Effect: "Allow",
        Action: [
          "ec2:AuthorizeSecurityGroupIngress", "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress", "ec2:RevokeSecurityGroupEgress",
          "ec2:UpdateSecurityGroupRuleDescriptionsIngress",
          "ec2:UpdateSecurityGroupRuleDescriptionsEgress"
        ],
        Resource: "*"
      },

      # Default Network ACL entry management
      # (the aws_default_network_acl resource manages entries & assoc)
      {
        Sid: "DefaultNaclEntries",
        Effect: "Allow",
        Action: [
          "ec2:CreateNetworkAclEntry", "ec2:DeleteNetworkAclEntry",
          "ec2:ReplaceNetworkAclEntry", "ec2:ReplaceNetworkAclAssociation"
        ],
        Resource: "*"
      },

      # VPC Endpoints (Gateway & Interface)
      {
        Sid: "VpcEndpoints",
        Effect: "Allow",
        Action: [
          "ec2:CreateVpcEndpoint", "ec2:ModifyVpcEndpoint", "ec2:DeleteVpcEndpoints"
        ],
        Resource: "*"
      },

      # ELB/SSM describe (often used by modules/data sources)
      {
        Sid: "ELBAndSSMDescribe",
        Effect: "Allow",
        Action: [
          "elasticloadbalancing:Describe*",
          "ssm:Describe*", "ssm:Get*", "ssm:List*"
        ],
        Resource: "*"
      }
    ]
  })
}
