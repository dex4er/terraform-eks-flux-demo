## Security group cannot be deleted if there are still network interfaces even
## if EC2 instances are terminated. Removing them manually on `terraform
## destroy` allows to destroy security group too.

resource "shell_script" "sg_node_group_cleanup" {
  triggers = {
    security_group_id = module.sg_node_group.security_group_id
  }

  environment = {
    profile           = var.profile
    region            = var.region
    security_group_id = module.sg_node_group.security_group_id
  }

  working_directory = path.module

  lifecycle_commands {
    create = ":"
    update = ":"
    read   = <<-EOT
      echo "{\"security_group_id\":\"$security_group_id\"}"
    EOT
    delete = ". ${path.module}/sg_node_group_cleanup_destroy.sh"
  }
}

locals {
  ## Makes dependency on this resource so it should be destroyed in right time
  sg_node_group_id = shell_script.sg_node_group_cleanup.triggers.security_group_id
}
