## Bootstrap Flux. Because it is server-side applying it can't be added in one
## step with Flux repositories and kustomizations.

resource "null_resource" "flux_bootstrap" {
  triggers = {
    cluster_context      = local.cluster_context
    kubeconfig_parameter = aws_ssm_parameter.kubeconfig.name
    region               = var.region
    resource             = "flux_bootstrap"
  }

  provisioner "local-exec" {
    command     = "rm -rf .asdf-${self.triggers.resource} && git clone https://github.com/asdf-vm/asdf.git .asdf-${self.triggers.resource} --branch v0.11.2 && . .asdf-${self.triggers.resource}/asdf.sh && while read plugin version; do asdf plugin add $plugin || test $? = 2; done < .tool-versions; asdf install"
    interpreter = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    command     = ". .asdf-${self.triggers.resource}/asdf.sh && kubectl apply -k flux/flux-system --server-side --force-conflicts --kubeconfig <(aws ssm get-parameter --region ${var.region} --name ${aws_ssm_parameter.kubeconfig.name} --output text --query Parameter.Value --with-decryption) --context ${local.cluster_context}"
    interpreter = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "rm -rf .asdf-${self.triggers.resource} && git clone https://github.com/asdf-vm/asdf.git .asdf-${self.triggers.resource} --branch v0.11.2 && . .asdf-${self.triggers.resource}/asdf.sh && while read plugin version; do asdf plugin add $plugin || test $? = 2; done < .tool-versions; asdf install"
    interpreter = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    when        = destroy
    command     = ". .asdf-${self.triggers.resource}/asdf.sh && flux uninstall --keep-namespace=true --silent --kubeconfig <(aws ssm get-parameter --region ${self.triggers.region} --name ${self.triggers.kubeconfig_parameter} --output text --query Parameter.Value --with-decryption) --context ${self.triggers.cluster_context}"
    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [
    aws_eks_addon.this,
  ]
}
