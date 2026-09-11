terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# Primary region: hosts ECR, App Runner, and the static-assets S3 bucket.
provider "aws" {
  region = var.aws_region
}

# CloudFront's ACM certificate must live in us-east-1 regardless of which
# region the rest of the stack is in.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
