locals {
  aws_region = "us-east-2"
}

terraform {
  backend "s3" {
    bucket = "farofus-terraform"
    key    = "desktop/terraform.tfstate"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "cloudflare" {}

provider "aws" {
  region = local.aws_region
}

provider "digitalocean" {}
