terraform {
  backend "s3" {
    bucket = "farofus-terraform"
    key    = "desktop/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "cloudflare" {}

provider "aws" {
  region = "us-east-1"
}
