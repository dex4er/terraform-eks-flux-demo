## It is potentially dangerous to clean up security groups and network
## interfaces but they're leftovers from working EKS cluster and they'll hold
## `terraform destroy` for long time otherway.

locals {
  vpc_cleanup_environment = {
    asdf_dir = var.asdf_dir
    profile  = var.profile
    region   = var.region
    vpc_id   = module.vpc.vpc_id
  }
}

resource "shell_script" "vpc_cleanup" {
  triggers = local.vpc_cleanup_environment

  environment = local.vpc_cleanup_environment

  working_directory = path.module

  lifecycle_commands {
    create = <<-EOT
      echo '{"checksum":"${sha256(jsonencode(local.vpc_cleanup_environment))}"}'
    EOT
    update = <<-EOT
      echo '{"checksum":"${sha256(jsonencode(local.vpc_cleanup_environment))}"}'
    EOT
    read   = <<-EOT
      echo '{"checksum":"${sha256(jsonencode(local.vpc_cleanup_environment))}"}'
    EOT
    delete = file("${path.module}/vpc_cleanup_destroy.sh")
  }
}

locals {
  vpc_id = shell_script.vpc_cleanup.triggers.vpc_id
}
