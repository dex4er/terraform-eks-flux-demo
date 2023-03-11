## Install main Flux kustomization

resource "null_resource" "flux_kustomization_all" {
  triggers = {
    cluster_context = local.cluster_context
  }
  provisioner "local-exec" {
    command = "kubectl apply -f flux/all.yaml --server-side --force-conflicts --kubeconfig .kube/config --context ${local.cluster_context} && sleep 120"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl get kustomization all -n flux-system --no-headers --kubeconfig .kube/config --context ${self.triggers.cluster_context} | while read name _rest; do flux suspend ks $name --kubeconfig .kube/config --context ${self.triggers.cluster_context}; done && kubectl get kustomization -n flux-system --no-headers --kubeconfig .kube/config --context ${self.triggers.cluster_context} | grep -v -P '^(all|aws-load-balancer-controller|flux-system)' | while read name _rest; do kubectl delete kustomization $name -n flux-system --ignore-not-found --kubeconfig .kube/config --context ${self.triggers.cluster_context}; done && sleep 300 && kubectl get kustomization -n flux-system --no-headers --kubeconfig .kube/config --context ${self.triggers.cluster_context} | grep -v -P '^(all|flux-system)' | while read name _rest; do kubectl delete kustomization $name -n flux-system --ignore-not-found --kubeconfig .kube/config --context ${self.triggers.cluster_context}; done && sleep 60 && kubectl delete -f flux/all.yaml --ignore-not-found --kubeconfig .kube/config --context ${self.triggers.cluster_context} && sleep 60"
  }

  depends_on = [
    null_resource.aws_eks_update-kubeconfig_terraform,
    null_resource.flux_bootstrap,
    null_resource.flux_cluster_vars,
    null_resource.flux_ocirepository,
  ]
}
