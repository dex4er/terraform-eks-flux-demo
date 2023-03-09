## This file is a bridge between Terraform and Flux. More parameters might be
## passed to the cluster with usage of external-secrets.io but some of them are
## necessary before external-servers is even started.

resource "local_file" "flux_cluster_vars" {
  content = join("\n", concat([
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
  filename             = "flux/flux-system/cluster-vars.env"
  directory_permission = "0755"
  file_permission      = "0644"
}
