data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
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

  bucket_prefix_name = var.bucket_prefix_name
  lock_table         = var.lock_table

  # decide per environment:
  #create_bucket      = var.create_bucket   # set false if the bucket already exists
  #create_lock_table  = var.create_lock_table   # set false if the table already exists
  
  create_bucket      = var.create_bucket     && length(trimspace(var.existing_bucket_name))  == 0
  create_lock_table  = var.create_lock_table && length(trimspace(var.existing_lock_table))   == 0
  
  state_key          = "envs/${var.environment}/terraform.tfstate"

  existing_bucket_name = var.existing_bucket_name
  existing_lock_table  = var.existing_lock_table
}

module "iam_tf_policies" {
  source          = "./modules/iam_tf_policies"

  bucket_name     = module.s3_bucket_state_oidc.s3_bucket_id
  lock_table_name = module.s3_bucket_state_oidc.lock_table_name
  region          = var.region

  existing_backend_rw_policy_arn = var.existing_backend_rw_policy_arn
  existing_vpc_apply_policy_arn  = var.existing_vpc_apply_policy_arn
  # ensure bucket/table exist first
  depends_on = [module.s3_bucket_state_oidc]
}

module "github_oidc" {
  source = "./modules/github_oidc"

  create_oidc_provider = var.create_oidc_provider
  create_oidc_role     = var.create_oidc_role
  oidc_provider_arn    = var.oidc_provider_arn
  oidc_role_attach_policies = [
    module.iam_tf_policies.tf_backend_rw_policy_arn,
    module.iam_tf_policies.tf_vpc_apply_policy_arn
  ]

  repositories = var.repository_list

  depends_on = [module.iam_tf_policies]
}