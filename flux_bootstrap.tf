## Bootstrap Flux. Because it is server-side applying it can't be added in one
## step with Flux repositories and kustomizations.

resource "null_resource" "flux_bootstrap" {
  triggers = {
    cluster_context      = local.cluster_context
    kubeconfig_parameter = aws_ssm_parameter.kubeconfig.name
    region               = var.region
  }

  provisioner "local-exec" {
    command     = ". .asdf/asdf.sh && kubectl apply -k flux/flux-system --server-side --force-conflicts --kubeconfig <(aws ssm get-parameter --region ${var.region} --name ${aws_ssm_parameter.kubeconfig.name} --output text --query Parameter.Value --with-decryption) --context ${local.cluster_context}"
    interpreter = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    when        = destroy
    command     = ". .asdf/asdf.sh && flux uninstall --keep-namespace=true --silent --kubeconfig <(aws ssm get-parameter --region ${self.triggers.region} --name ${self.triggers.kubeconfig_parameter} --output text --query Parameter.Value --with-decryption) --context ${self.triggers.cluster_context}"
    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [
    aws_eks_addon.this,
    null_resource.asdf_install,
  ]
}
