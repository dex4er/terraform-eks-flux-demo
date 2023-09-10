## Security group cannot be deleted if there are still network interfaces even
## if EC2 instances are terminated. Removing them manually on `terraform
## destroy` allows to destroy security group too.

locals {
  sg_node_group_cleanup_environment = {
    asdf_dir          = var.asdf_dir
    profile           = var.profile
    region            = var.region
    security_group_id = module.sg_node_group.security_group_id
  }
}

resource "shell_script" "sg_node_group_cleanup" {
  triggers = local.sg_node_group_cleanup_environment

  environment = local.sg_node_group_cleanup_environment

  working_directory = path.module

  lifecycle_commands {
    create = "true"
    update = "true"
    delete = file("${path.module}/sg_node_group_cleanup_destroy.sh")
  }
}

locals {
  sg_node_group_id = shell_script.sg_node_group_cleanup.triggers.security_group_id
}
