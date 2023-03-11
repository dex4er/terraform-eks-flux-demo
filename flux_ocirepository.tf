## This file can't be generated by Flux using cluster-vars ConfigMap

resource "null_resource" "flux_ocirepository" {
  triggers = {
    cluster_context            = local.cluster_context
    flux_system_repository_url = local.flux_system_repository_url
    kubeconfig_parameter       = aws_ssm_parameter.kubeconfig.name
  }

  provisioner "local-exec" {
    command     = ". .asdf/asdf.sh && kubectl delete ocirepository -n flux-system flux-system --ignore-not-found --kubeconfig <(aws ssm get-parameter --region ${var.region} --name ${aws_ssm_parameter.kubeconfig.name} --output text --query Parameter.Value --with-decryption) --context ${self.triggers.cluster_context} && flux create source oci flux-system --url=oci://${local.flux_system_repository_url} --tag=latest --provider=aws --kubeconfig <(aws ssm get-parameter --region ${var.region} --name ${aws_ssm_parameter.kubeconfig.name} --output text --query Parameter.Value --with-decryption) --context ${local.cluster_context}"
    interpreter = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    when        = destroy
    command     = ". .asdf/asdf.sh && kubectl delete ocirepository -n flux-system flux-system --ignore-not-found --kubeconfig <(aws ssm get-parameter --region ${var.region} --name ${self.triggers.kubeconfig_parameter} --output text --query Parameter.Value --with-decryption) --context ${self.triggers.cluster_context}"
    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [
    module.ecr_flux_system,
    null_resource.asdf_install,
    null_resource.flux_bootstrap,
  ]
}
