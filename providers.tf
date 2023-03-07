terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.56.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.3.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.18.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.1"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.9.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.4"
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

provider "aws" {
  alias = "global"

  allowed_account_ids = [var.account_id]
  region              = "us-east-1"

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
