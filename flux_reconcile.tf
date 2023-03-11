## Reconcile Flux `flux-system` source repository and `all` kustomization.

resource "null_resource" "flux_reconcile" {
  triggers = {
    flux_directory_checksum = null_resource.flux_push_artifact.triggers.flux_directory_checksum
  }

  provisioner "local-exec" {
    command     = ". .asdf/asdf.sh && flux reconcile source oci flux-system --kubeconfig <(aws ssm get-parameter --region ${var.region} --name ${aws_ssm_parameter.kubeconfig.name} --output text --query Parameter.Value --with-decryption) --context ${local.cluster_context} && flux reconcile ks all --kubeconfig <(aws ssm get-parameter --region ${var.region} --name ${aws_ssm_parameter.kubeconfig.name} --output text --query Parameter.Value --with-decryption) --context ${local.cluster_context}"
    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [
    null_resource.flux_kustomization_all,
  ]
}
