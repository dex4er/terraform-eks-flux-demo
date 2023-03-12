## Bootstrap Flux. Because it is server-side applying it can't be added in one
## step with Flux repositories and kustomizations.

resource "null_resource" "flux_bootstrap" {
  triggers = {
    asdf_dir             = coalesce(var.asdf_dir, ".asdf-flux_bootstrap")
    asdf_tools           = "awscli flux2 kubectl"
    cluster_context      = local.cluster_context
    kubeconfig_parameter = aws_ssm_parameter.kubeconfig.name
    region               = var.region
  }

  provisioner "local-exec" {
    command     = "test -d ${self.triggers.asdf_dir} || git clone https://github.com/asdf-vm/asdf.git ${self.triggers.asdf_dir} --branch v0.11.2 && export ASDF_DATA_DIR=$PWD/${self.triggers.asdf_dir} && . ${self.triggers.asdf_dir}/asdf.sh && for plugin in ${self.triggers.asdf_tools}; do asdf plugin add $plugin || test $? = 2; asdf install $plugin; done"
    interpreter = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    command     = "export ASDF_DATA_DIR=$PWD/${self.triggers.asdf_dir} && . ${self.triggers.asdf_dir}/asdf.sh && kubectl apply -k flux/flux-system --server-side --force-conflicts --kubeconfig <(aws ssm get-parameter --region ${var.region} --name ${aws_ssm_parameter.kubeconfig.name} --output text --query Parameter.Value --with-decryption) --context ${local.cluster_context}"
    interpreter = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "test -d ${self.triggers.asdf_dir} || git clone https://github.com/asdf-vm/asdf.git ${self.triggers.asdf_dir} --branch v0.11.2 && export ASDF_DATA_DIR=$PWD/${self.triggers.asdf_dir} && . ${self.triggers.asdf_dir}/asdf.sh && for plugin in ${self.triggers.asdf_tools}; do asdf plugin add $plugin || test $? = 2; asdf install $plugin; done"
    interpreter = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "export ASDF_DATA_DIR=$PWD/${self.triggers.asdf_dir} && . ${self.triggers.asdf_dir}/asdf.sh && flux uninstall --keep-namespace=true --silent --kubeconfig <(aws ssm get-parameter --region ${self.triggers.region} --name ${self.triggers.kubeconfig_parameter} --output text --query Parameter.Value --with-decryption) --context ${self.triggers.cluster_context}"
    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [
    aws_eks_addon.this,
  ]
}
