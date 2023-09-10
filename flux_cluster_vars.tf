## This ConfigMap is a bridge between Terraform and Flux. More parameters might
## be passed to the cluster with usage of external-secrets.io but some of
## them are necessary before external-servers is even started.

locals {
  cluster_vars = join("\n", concat([
    "account_id=${var.account_id}",
    "account_id_string=\"${var.account_id}\"",
    "assume_role=${coalesce(var.assume_role, local.caller_identity)}"
    ], [for i, v in var.azs :
    "azs_id_${i}=${v}"
    ], [for i, v in var.azs :
    "azs_name_${i}=${data.aws_availability_zones.this[i].names[0]}"
    ], [
    "cluster_name=${var.cluster_name}",
    "region=${var.region}",
    "vpc_id=${local.vpc_id}",
  ]))

  flux_cluster_vars_environment = {
    asdf_dir                = var.asdf_dir
    account_id              = var.account_id
    azs                     = join(",", [for i, v in var.azs : "${i}=${v}"])
    cluster_context         = local.cluster_context
    cluster_vars_checksum   = sha256(local.cluster_vars)
    flux_git_repository_url = var.flux_git_repository_url
    kubeconfig_parameter    = aws_ssm_parameter.kubeconfig.name
    name                    = var.cluster_name
    profile                 = var.profile
    region                  = var.region
    vpc_id                  = local.vpc_id
  }
}

resource "shell_script" "flux_cluster_vars" {
  triggers = local.flux_cluster_vars_environment

  environment = local.flux_cluster_vars_environment

  working_directory = path.module

  lifecycle_commands {
    create = file("${path.module}/flux_cluster_vars.sh")
    update = file("${path.module}/flux_cluster_vars.sh")
    delete = file("${path.module}/flux_cluster_vars_destroy.sh")
  }

  depends_on = [
    shell_script.flux_bootstrap,
  ]
}
