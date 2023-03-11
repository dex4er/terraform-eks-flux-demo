## This ConfigMap is a bridge between Terraform and Flux. More parameters might
##  be passed to the cluster with usage of external-secrets.io but some of
## them are necessary before external-servers is even started.

resource "null_resource" "flux_cluster_vars" {
  triggers = {
    account_id                 = var.account_id
    azs                        = join(",", [for i, v in var.azs : "${i}=${v}"])
    cluster_context            = local.cluster_context
    flux_system_repository_url = local.flux_system_repository_url
    name                       = var.name
    region                     = var.region
    vpc_id                     = local.vpc_id
  }

  provisioner "local-exec" {
    command = join("", concat(["kubectl delete configmap -n flux-system cluster-vars --ignore-not-found --kubeconfig .kube/config --context ${self.triggers.cluster_context} && kubectl create configmap -n flux-system cluster-vars"], [
      " --from-literal=account_id=${var.account_id}",
      " --from-literal=account_id_string='\"${var.account_id}\"'",
      ], [for i, v in var.azs :
      " --from-literal=azs_id_${i}=${v}"
      ], [for i, v in var.azs :
      " --from-literal=azs_name_${i}=${data.aws_availability_zones.this[i].names[0]}"
      ], [
      " --from-literal=cluster_name=${var.name}",
      " --from-literal=region=${var.region}",
      " --from-literal=vpc_id=${local.vpc_id}",
      " --kubeconfig .kube/config --context ${local.cluster_context}"
    ]))
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete configmap -n flux-system cluster-vars --ignore-not-found --kubeconfig .kube/config --context ${self.triggers.cluster_context}"
  }

  depends_on = [
    null_resource.aws_eks_update-kubeconfig_terraform,
    null_resource.flux_bootstrap,
  ]
}
