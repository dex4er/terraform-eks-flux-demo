## Bootstrap Flux

resource "null_resource" "flux_bootstrap" {
  triggers = {
    cluster_context = local.cluster_context
  }

  provisioner "local-exec" {
    command = "kubectl apply -k flux/flux-system --server-side --force-conflicts --kubeconfig .kube/config --context ${local.cluster_context}"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "flux uninstall --keep-namespace=true --silent --kubeconfig .kube/config --context ${self.triggers.cluster_context}"
  }

  depends_on = [
    null_resource.aws_eks_update-kubeconfig_terraform,
  ]
}
