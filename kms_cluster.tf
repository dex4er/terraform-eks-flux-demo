## The key used for cluster secrets.

locals {
  ## Must be between 7 and 30 (default)
  cluster_kms_key_deletion_window_in_days = 7
}

module "kms_cluster" {
  ## https://github.com/terraform-aws-modules/terraform-aws-kms
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 2.0"

  description = "${var.name} cluster encryption key"

  aliases = ["${var.name}-cluster"]

  deletion_window_in_days = local.cluster_kms_key_deletion_window_in_days

  key_owners = var.assume_role != null ? [var.assume_role] : []
  key_users  = ["arn:aws:iam::${var.account_id}:role/${var.name}-cluster"]

  tags = {
    Name   = "${var.name}-cluster"
    Object = "module.kms_cluster"
  }
}
