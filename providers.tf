provider "aws" {
  allowed_account_ids = [var.account_id]
  profile             = var.profile
  region              = var.region

  assume_role {
    role_arn     = var.assume_role
    session_name = "Terraform"
  }

  default_tags {
    tags = {
      Project   = var.cluster_name
      ManagedBy = "Terraform"
    }
  }
}

provider "aws" {
  alias = "global"

  allowed_account_ids = [var.account_id]
  profile             = var.profile
  region              = "us-east-1"

  assume_role {
    role_arn     = var.assume_role
    session_name = "Terraform"
  }

  default_tags {
    tags = {
      Project   = var.cluster_name
      ManagedBy = "Terraform"
    }
  }
}

provider "shell" {
  interpreter        = ["bash", "-c"]
  enable_parallelism = false
}
