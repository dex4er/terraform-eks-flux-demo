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

provider "helm" {
  kubernetes {
    host                   = local.cluster_endpoint
    cluster_ca_certificate = local.cluster_ca_certificate

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "${path.module}/eks_get_token.sh"
      args        = [module.eks.cluster_name]
    }
  }
}

provider "kubernetes" {
  host                   = local.cluster_endpoint
  cluster_ca_certificate = local.cluster_ca_certificate

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "${path.module}/eks_get_token.sh"
    args        = [module.eks.cluster_name]
  }
}

provider "shell" {
  interpreter        = ["bash", "-c"]
  enable_parallelism = false
}
