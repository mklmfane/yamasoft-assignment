data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  existing_provider_arn = "arn:aws:iam::${local.account_id}:oidc-provider/${var.oidc_provider_content}"
}

module "vpc" {
  source = "./modules/vpc"

  name = var.vpc_name
  cidr = "172.16.0.0/16"
  azs = ["eu-west-1a", "eu-west-1b"]

  private_subnets = [
    "172.16.0.0/20", 
    "172.16.16.0/20", 
    "172.16.32.0/20", 
    "172.16.48.0/20",
  ]

  public_subnets = [
    "172.16.64.0/20",
    "172.16.80.0/20",  
    "172.16.96.0/20", 
    "172.16.112.0/20", 
  ]

  enable_nat_gateway = true
  one_nat_gateway_per_az = true
  single_nat_gateway     = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}


module "s3_bucket_state_oidc" {
  source  = "./modules/s3_bucket_state"

  bucket_suffix_name = var.bucket_suffix_name
  lock_table         = var.lock_table
}

module "iam_tf_policies" {
  source          = "./modules/iam_tf_policies"

  bucket_name     = module.s3_bucket_state_oidc.s3_bucket_id
  lock_table_name = module.s3_bucket_state_oidc.lock_table_name
  region          = var.region


  # ensure bucket/table exist first
  depends_on = [module.s3_bucket_state_oidc]
}


module "github_oidc" {
  source = "./modules/github_oidc"

  create_oidc_provider        = false
  existing_oidc_provider_arn  = local.existing_provider_arn
  create_oidc_role            = true

  repositories = var.repository_list
  oidc_role_attach_policies = [
    module.iam_tf_policies.tf_backend_rw_policy_arn,
    module.iam_tf_policies.tf_vpc_apply_policy_arn
  ]

  depends_on = [
    module.iam_tf_policies
  ]
}
