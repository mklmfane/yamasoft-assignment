module "vpc" {
  source = "./modules/vpc"

  name = "my-vpc-tf-test"
  cidr = "172.16.0.0/16"

  azs = ["eu-west-1a", "eu-west-1b"]

  # 4 private subnets (2 per AZ)
  private_subnets = [
    "172.16.0.0/20", 
    "172.16.16.0/20", 
    "172.16.32.0/20", 
    "172.16.48.0/20",
  ]

  # 4 public subnets (2 per AZ)
  public_subnets = [
    "172.16.64.0/20",
    "172.16.80.0/20",  
    "172.16.96.0/20", 
    "172.16.112.0/20", 
  ]

  enable_nat_gateway = true
  # if you want one NAT per AZ:
  one_nat_gateway_per_az = true
  single_nat_gateway     = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
