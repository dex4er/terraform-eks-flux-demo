## Bootstrap Flux. Because it is server-side applying it can't be added in one
## step with Flux repositories and kustomizations.

resource "null_resource" "flux_bootstrap" {
  triggers = {
    asdf_dir             = coalesce(var.asdf_dir, ".asdf-flux_bootstrap")
    asdf_tools           = "awscli flux2 kubectl"
    cluster_context      = local.cluster_context
    kubeconfig_parameter = aws_ssm_parameter.kubeconfig.name
    region               = var.region
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/asdf_install.sh"
    environment = {
      asdf_dir   = self.triggers.asdf_dir
      asdf_tools = self.triggers.asdf_tools
    }
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/flux_bootstrap.sh"
    environment = {
      asdf_dir             = self.triggers.asdf_dir
      cluster_context      = self.triggers.cluster_context
      kubeconfig_parameter = self.triggers.kubeconfig_parameter
      region               = self.triggers.region
    }
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
    command = "bash ${path.module}/flux_bootstrap_destroy.sh"
    environment = {
      asdf_dir             = self.triggers.asdf_dir
      cluster_context      = self.triggers.cluster_context
      kubeconfig_parameter = self.triggers.kubeconfig_parameter
      region               = self.triggers.region
    }
  }

  depends_on = [
    aws_eks_addon.this,
  ]
}
