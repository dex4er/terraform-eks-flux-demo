## Clean up Flux deployments before uninstalling it

resource "shell_script" "flux_cleanup" {
  environment = {
    cluster_context      = local.cluster_context
    kubeconfig_parameter = aws_ssm_parameter.kubeconfig.name
    profile              = var.profile
    region               = var.region
    script_checksum      = sha256(file("${path.module}/flux_cleanup_destroy.sh"))
  }

  working_directory = path.module

  lifecycle_commands {
    create = ":"
    update = ":"
    read   = <<-EOT
      echo "{\"checksum\":\"$script_checksum\"}"
    EOT
    delete = ". ${path.module}/flux_cleanup_destroy.sh"
  }

  depends_on = [helm_release.flux_instance]
}
