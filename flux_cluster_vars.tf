## This ConfigMap is a bridge between Terraform and Flux. More parameters might
## be passed to the cluster with usage of external-secrets.io but some of
## them are necessary before external-servers is even started.

locals {
  cluster_vars = join("\n", concat([
    "account_id=${var.account_id}",
    "account_id_string=\"${var.account_id}\"",
    "admin_role_arn=${coalesce(var.admin_role_arn, local.caller_identity)}"
    ], [for i, v in var.azs :
    "azs_id_${i}=${v}"
    ], [for i, v in var.azs :
    "azs_name_${i}=${data.aws_availability_zones.this[i].names[0]}"
    ], [
    "cluster_name=${var.cluster_name}",
    "flux_git_repository_url=${var.flux_git_repository_url}",
    "region=${var.region}",
    "vpc_id=${local.vpc_id}",
  ]))
}

resource "shell_script" "flux_cluster_vars" {
  environment = {
    asdf_dir             = var.asdf_dir
    cluster_context      = local.cluster_context
    cluster_vars         = local.cluster_vars
    kubeconfig_parameter = aws_ssm_parameter.kubeconfig.name
    profile              = var.profile
    region               = var.region
    script_checksum      = sha256(file("${path.module}/flux_cluster_vars.sh"))
  }

  working_directory = path.module

  lifecycle_commands {
    create = ". ${path.module}/flux_cluster_vars.sh"
    update = ". ${path.module}/flux_cluster_vars.sh"
    read   = <<-EOT
      echo "{\"checksum\":\"$script_checksum\"}"
    EOT
    delete = ". ${path.module}/flux_cluster_vars_destroy.sh"
  }

  depends_on = [
    module.eks,
    module.iam_role_cluster,
    module.iam_role_node_group,
    module.irsa_aws_load_balancer_controller,
    module.irsa_aws_vpc_cni,
    module.kms_cluster,
    module.sg_cluster,
    module.sg_node_group,
    module.sg_vpce,
    module.vpc,
  ]
}
