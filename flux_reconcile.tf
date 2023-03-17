## Reconcile Flux `flux-system` source repository and `all` kustomization.

resource "null_resource" "flux_reconcile" {
  triggers = {
    asdf_dir                = coalesce(var.asdf_dir, "$PWD/.asdf-flux_reconcile")
    asdf_tools              = "awscli flux2"
    flux_directory_checksum = null_resource.flux_push_artifact.triggers.flux_directory_checksum
    region                  = var.region
  }

  provisioner "local-exec" {
    command     = "test -d ${self.triggers.asdf_dir} || git clone https://github.com/asdf-vm/asdf.git ${self.triggers.asdf_dir} --branch v0.11.2 && export ASDF_DATA_DIR=${self.triggers.asdf_dir} && . ${self.triggers.asdf_dir}/asdf.sh && cd ${self.triggers.asdf_dir} && for plugin in ${self.triggers.asdf_tools}; do asdf plugin add $plugin || test $? = 2; asdf install $plugin; done"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      AWS_REGION = self.triggers.region
    }
  }

  provisioner "local-exec" {
    command     = "export ASDF_DATA_DIR=${self.triggers.asdf_dir} && . ${self.triggers.asdf_dir}/asdf.sh && flux reconcile source oci flux-system --kubeconfig <(aws ssm get-parameter --region ${var.region} --name ${aws_ssm_parameter.kubeconfig.name} --output text --query Parameter.Value --with-decryption) --context ${local.cluster_context} && flux reconcile ks all --kubeconfig <(aws ssm get-parameter --region ${var.region} --name ${aws_ssm_parameter.kubeconfig.name} --output text --query Parameter.Value --with-decryption) --context ${local.cluster_context}"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      AWS_REGION = self.triggers.region
    }
  }

  depends_on = [
    null_resource.flux_kustomization_all,
  ]
}
