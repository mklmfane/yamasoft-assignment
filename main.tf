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

module "github-oidc" {
  source  = "./modules/github-oidc"

  create_oidc_provider = true  # set true only during bootstrap with admin creds
  create_oidc_role     = true

  repositories = var.repository_list
  oidc_role_attach_policies = [
    aws_iam_policy.tf_backend_rw.arn,
    aws_iam_policy.tf_vpc_apply.arn
  ]
}