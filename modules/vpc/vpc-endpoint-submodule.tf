module "vpc_endpoints" {
  source = "./modules/vpc-endpoints"

  vpc_id             = aws_vpc.this[0].id
  security_group_ids = [aws_default_security_group.this[0].id]   # used by Interface endpoints
  subnet_ids         = aws_subnet.private[*].id                  # used by Interface endpoints

  endpoints = {
    ssm = {
      service             = "ssm"
      service_type        = "Interface"
      private_dns_enabled = true
    }

    s3 = {
      service         = "s3"
      service_type    = "Gateway"                     
      route_table_ids = aws_route_table.private[*].id
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}
