## Bootstrap Flux. Because it is server-side applying it can't be added in one
## step with Flux repositories and kustomizations.

locals {
  flux_bootstrap_environment = {
    asdf_dir                = var.asdf_dir
    cluster_context         = local.cluster_context
    flux_git_repository_url = var.flux_git_repository_url
    kubeconfig_parameter    = aws_ssm_parameter.kubeconfig.name
    profile                 = coalesce(var.profile, "")
    region                  = var.region
  }
}

resource "shell_script" "flux_bootstrap" {
  triggers = local.flux_bootstrap_environment

  environment = local.flux_bootstrap_environment

  working_directory = path.module

  lifecycle_commands {
    create = file("${path.module}/flux_bootstrap.sh")
    update = file("${path.module}/flux_bootstrap.sh")
    delete = file("${path.module}/flux_bootstrap_destroy.sh")
  }

  depends_on = [
    aws_eks_addon.this,
  ]
}
