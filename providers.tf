provider "aws" {
  allowed_account_ids = [var.account_id]
  profile             = var.profile
  region              = var.region

  dynamic "assume_role" {
    for_each = toset(var.assume_role != null ? [var.assume_role] : [])

    content {
      role_arn     = assume_role.key
      session_name = "Terraform"
    }
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

  dynamic "assume_role" {
    for_each = toset(var.assume_role != null ? [var.assume_role] : [])

    content {
      role_arn     = assume_role.key
      session_name = "Terraform"
    }
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
