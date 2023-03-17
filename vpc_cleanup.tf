## It is potentially dangerous to clean up security groups and network
## interfaces but they're leftovers from working EKS cluster and they'll hold
## `terraform destroy` for long time otherway.

resource "null_resource" "vpc_cleanup" {
  triggers = {
    asdf_dir   = coalesce(var.asdf_dir, ".vpc_cleanup")
    asdf_tools = "awscli"
    region     = var.region
    vpc_id     = module.vpc.vpc_id
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
    command = "bash ${path.module}/vpc_cleanup_destroy.sh"
    environment = {
      asdf_dir = self.triggers.asdf_dir
      region   = self.triggers.region
      vpc_id   = self.triggers.vpc_id
    }
  }
}

locals {
  vpc_id = null_resource.vpc_cleanup.triggers.vpc_id
}
