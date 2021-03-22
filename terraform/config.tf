locals {
  aws_region = "us-east-2"
}

terraform {
  backend "s3" {
    bucket = "farofus-terraform"
    key    = "desktop/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "cloudflare" {}

provider "aws" {
  region = local.aws_region
}
