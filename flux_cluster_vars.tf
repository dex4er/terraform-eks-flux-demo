## This ConfigMap is a bridge between Terraform and Flux. More parameters might
## be passed to the cluster with usage of external-secrets.io but some of
## them are necessary before external-servers is even started.

locals {
  cluster_vars = join("\n", concat([
    "account_id=${var.account_id}",
    "account_id_string=\"${var.account_id}\"",
    ], [for i, v in var.azs :
    "azs_id_${i}=${v}"
    ], [for i, v in var.azs :
    "azs_name_${i}=${data.aws_availability_zones.this[i].names[0]}"
    ], [
    "cluster_name=${var.name}",
    "region=${var.region}",
    "vpc_id=${local.vpc_id}",
  ]))
}

resource "null_resource" "flux_cluster_vars" {
  triggers = {
    asdf_dir                   = coalesce(var.asdf_dir, ".asdf-flux_cluster_vars")
    asdf_tools                 = "awscli kubectl"
    account_id                 = var.account_id
    azs                        = join(",", [for i, v in var.azs : "${i}=${v}"])
    cluster_context            = local.cluster_context
    cluster_vars_checksum      = sha256(local.cluster_vars)
    flux_system_repository_url = local.flux_system_repository_url
    kubeconfig_parameter       = aws_ssm_parameter.kubeconfig.name
    name                       = var.name
    region                     = var.region
    vpc_id                     = local.vpc_id
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/asdf_install.sh"
    environment = {
      asdf_dir   = self.triggers.asdf_dir
      asdf_tools = self.triggers.asdf_tools
    }
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/flux_cluster_vars.sh"
    environment = {
      asdf_dir             = self.triggers.asdf_dir
      cluster_context      = self.triggers.cluster_context
      cluster_vars         = local.cluster_vars
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
    command = "bash ${path.module}/flux_cluster_vars_destroy.sh"
    environment = {
      asdf_dir             = self.triggers.asdf_dir
      cluster_context      = self.triggers.cluster_context
      kubeconfig_parameter = self.triggers.kubeconfig_parameter
      region               = self.triggers.region
    }
  }

  depends_on = [
    null_resource.flux_bootstrap,
  ]
}
