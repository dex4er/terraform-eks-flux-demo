## It is potentially dangerous to clean up security groups and network
## interfaces but they're leftovers from working EKS cluster and they'll hold
## `terraform destroy` for long time otherway.

resource "shell_script" "vpc_cleanup" {
  triggers = {
    vpc_id = module.vpc.vpc_id
  }

  environment = {
    asdf_dir = var.asdf_dir
    profile  = var.profile
    region   = var.region
    vpc_id   = module.vpc.vpc_id
  }

  working_directory = path.module

  lifecycle_commands {
    create = ":"
    update = ":"
    read   = <<-EOT
      echo "{\"vpc_id\":\"$vpc_id\"}"
    EOT
    delete = ". ${path.module}/vpc_cleanup_destroy.sh"
  }
}

locals {
  ## Makes dependency on this resource so it should be destroyed in right time
  vpc_id = shell_script.vpc_cleanup.triggers.vpc_id
}
