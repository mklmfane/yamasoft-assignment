terraform {
  required_version = ">= 1.3.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  
   }

  backend "s3" {}
}

provider "aws" {
  region  = "eu-west-1"
  shared_credentials_files = ["~/.aws/credentials"]
  shared_config_files      = ["~/.aws/config"]

  profile = "Admiinstratoraccess-049419512437"

}