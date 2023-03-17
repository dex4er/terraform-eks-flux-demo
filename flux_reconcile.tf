## Reconcile Flux `flux-system` source repository and `all` kustomization.

resource "null_resource" "flux_reconcile" {
  triggers = {
    asdf_dir                = coalesce(var.asdf_dir, ".asdf-flux_reconcile")
    asdf_tools              = "awscli flux2"
    flux_directory_checksum = null_resource.flux_push_artifact.triggers.flux_directory_checksum
    region                  = var.region
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/asdf_install.sh"
    environment = {
      asdf_dir   = self.triggers.asdf_dir
      asdf_tools = self.triggers.asdf_tools
    }
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/flux_reconcile.sh"
    environment = {
      asdf_dir             = self.triggers.asdf_dir
      cluster_context      = self.triggers.cluster_context
      kubeconfig_parameter = self.triggers.kubeconfig_parameter
      region               = self.triggers.region
    }
  }

  depends_on = [
    null_resource.flux_kustomization_all,
  ]
}
