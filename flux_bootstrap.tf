## Bootstrap Flux:
##
## 1. install CRDs and main manifest
## 2. install sources and kustomization
## 3. install main Flux kustomization

resource "null_resource" "apply_flux_system" {
  provisioner "local-exec" {
    command = "kubectl apply -k flux/flux-system-install --server-side --kubeconfig .kube/config --context ${local.cluster_context} && kubectl apply -k flux/flux-system --server-side --kubeconfig .kube/config --context ${local.cluster_context} && kubectl apply -f flux/all.yaml --server-side --kubeconfig .kube/config --context ${local.cluster_context}"
  }

  depends_on = [
    null_resource.aws_eks_update-kubeconfig_terraform,
  ]
}
