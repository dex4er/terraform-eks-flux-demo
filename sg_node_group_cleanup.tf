## Security group cannot be deleted if there are still network interfaces even
## if EC2 instances are terminated. Removing them manually on `terraform
## destroy` allows to destroy security group too.

resource "null_resource" "sg_node_group_cleanup" {
  triggers = {
    asdf_dir          = coalesce(var.asdf_dir, ".asdf-sg_node_group_cleanup")
    asdf_tools        = "awscli"
    region            = var.region
    security_group_id = module.sg_node_group.security_group_id
  }

  provisioner "local-exec" {
    when    = destroy
    command = "bash ${path.module}/asdf_install.sh"
    environment = {
      asdf_dir   = self.triggers.asdf_dir
      asdf_tools = self.triggers.asdf_tools
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "bash ${path.module}/sg_node_group_cleanup_destroy.sh"
    environment = {
      asdf_dir          = self.triggers.asdf_dir
      region            = self.triggers.region
      security_group_id = self.triggers.security_group_id
    }
  }
}

locals {
  sg_node_group_id = null_resource.sg_node_group_cleanup.triggers.security_group_id
}
