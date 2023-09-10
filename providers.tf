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
