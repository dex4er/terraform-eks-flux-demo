## Push ./flux directory to ECR repository

data "archive_file" "flux" {
  type        = "zip"
  source_dir  = "flux"
  output_path = ".flux.zip"
}

resource "null_resource" "flux_push_artifact" {
  triggers = {
    account_id                 = var.account_id
    asdf_dir                   = coalesce(var.asdf_dir, ".asdf-flux_push_artifact")
    asdf_tools                 = "awscli flux2 go-containerregistry"
    flux_system_repository_url = local.flux_system_repository_url
    flux_directory_checksum    = data.archive_file.flux.output_base64sha256
    region                     = var.region
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/asdf_install.sh"
    environment = {
      asdf_dir   = self.triggers.asdf_dir
      asdf_tools = self.triggers.asdf_tools
    }
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/flux_push_artifacts.sh"
    environment = {
      account_id                 = self.triggers.account_id
      asdf_dir                   = self.triggers.asdf_dir
      cluster_context            = self.triggers.cluster_context
      flux_system_repository_url = self.triggers.flux_system_repository_url
      kubeconfig_parameter       = self.triggers.kubeconfig_parameter
      region                     = self.triggers.region
    }
  }
}
