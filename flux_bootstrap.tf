## Bootstrap Flux. Because it is server-side applying it can't be added in one
## step with Flux repositories and kustomizations.

resource "shell_script" "flux_bootstrap" {
  environment = {
    asdf_dir                = var.asdf_dir
    cluster_context         = local.cluster_context
    flux_git_repository_url = var.flux_git_repository_url
    kubeconfig_parameter    = aws_ssm_parameter.kubeconfig.name
    profile                 = var.profile
    region                  = var.region
    script_checksum         = sha256(file("${path.module}/flux_bootstrap.sh"))
  }

  working_directory = path.module

  lifecycle_commands {
    create = ". ${path.module}/flux_bootstrap.sh"
    update = ". ${path.module}/flux_bootstrap.sh"
    read   = <<-EOT
      echo "{\"checksum\":\"$script_checksum\"}"
    EOT
    delete = ". ${path.module}/flux_bootstrap_destroy.sh"
  }

  depends_on = [
    aws_eks_addon.this,
    shell_script.flux_cluster_vars,
  ]
}
