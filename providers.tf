terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.56.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.1"
    }
  }
}

provider "aws" {
  allowed_account_ids = [var.account_id]
  region              = var.region

  assume_role {
    role_arn     = var.assume_role
    session_name = "Terraform"
  }

  default_tags {
    tags = {
      Project   = var.name
      ManagedBy = "Terraform"
    }
  }
}
