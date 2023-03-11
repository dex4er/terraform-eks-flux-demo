## Reconcile Flux `flux-system` source repository and `all` kustomization.

resource "null_resource" "flux_reconcile" {
  triggers = {
    flux_directory_checksum = null_resource.flux_push_artifact.triggers.flux_directory_checksum
  }

  provisioner "local-exec" {
    command = "flux reconcile source oci flux-system --kubeconfig .kube/config --context ${local.cluster_context} && flux reconcile ks all --kubeconfig .kube/config --context ${local.cluster_context}"
  }

  depends_on = [
    null_resource.flux_kustomization_all,
  ]
}
