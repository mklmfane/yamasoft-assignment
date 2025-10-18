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


module "s3-bucket-state-oidc" {
  source  = "./modules/s3_bucket_state"

  bucket_suffix_name = var.bucket_suffix_name
  lock_table         = var.lock_table
}

module "iam-tf-policies" {
  source          = "./modules/iam-tf-policies"

  bucket_name     = module.s3-bucket-state-oidc.s3_bucket_id
  lock_table_name = module.s3-bucket-state-oidc.lock_table_name
  region          = var.region

  existing_backend_rw_policy_arn = ""
  existing_vpc_apply_policy_arn = ""

  # ensure bucket/table exist first
  depends_on = [module.s3-bucket-state-oidc]
}


module "github-oidc" {
  source  = "./modules/github-oidc"

  create_oidc_provider       = true
  create_oidc_role           = true
  repositories               = var.repository_list
  oidc_role_attach_policies  = [
    module.iam-tf-policies.tf_backend_rw_policy_arn,
    module.iam-tf-policies.tf_vpc_apply_policy_arn
  ]

  depends_on = [
    module.iam-tf-policies
  ]
}

