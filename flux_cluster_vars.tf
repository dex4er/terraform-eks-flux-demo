## This ConfigMap is a bridge between Terraform and Flux. More parameters might
## be passed to the cluster with usage of external-secrets.io but some of
## them are necessary before external-servers is even started.

resource "null_resource" "flux_cluster_vars" {
  triggers = {
    asdf_dir                   = coalesce(var.asdf_dir, ".asdf-flux_cluster_vars")
    asdf_tools                 = "awscli kubectl"
    account_id                 = var.account_id
    azs                        = join(",", [for i, v in var.azs : "${i}=${v}"])
    cluster_context            = local.cluster_context
    flux_system_repository_url = local.flux_system_repository_url
    kubeconfig_parameter       = aws_ssm_parameter.kubeconfig.name
    name                       = var.name
    region                     = var.region
    vpc_id                     = local.vpc_id
  }

  provisioner "local-exec" {
    command     = "test -d ${self.triggers.asdf_dir} || git clone https://github.com/asdf-vm/asdf.git ${self.triggers.asdf_dir} --branch v0.11.2 && export ASDF_DATA_DIR=$PWD/${self.triggers.asdf_dir} && . ${self.triggers.asdf_dir}/asdf.sh && for plugin in ${self.triggers.asdf_tools}; do asdf plugin add $plugin || test $? = 2; asdf install $plugin; done"
    interpreter = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    command = join("", concat(["export ASDF_DATA_DIR=$PWD/${self.triggers.asdf_dir} && . ${self.triggers.asdf_dir}/asdf.sh && kubectl delete configmap -n flux-system cluster-vars --ignore-not-found --kubeconfig <(aws ssm get-parameter --region ${var.region} --name ${aws_ssm_parameter.kubeconfig.name} --output text --query Parameter.Value --with-decryption) --context ${self.triggers.cluster_context} && kubectl create configmap -n flux-system cluster-vars"], [
      " --from-literal=account_id=${var.account_id}",
      " --from-literal=account_id_string='\"${var.account_id}\"'",
      ], [for i, v in var.azs :
      " --from-literal=azs_id_${i}=${v}"
      ], [for i, v in var.azs :
      " --from-literal=azs_name_${i}=${data.aws_availability_zones.this[i].names[0]}"
      ], [
      " --from-literal=cluster_name=${var.name}",
      " --from-literal=region=${var.region}",
      " --from-literal=vpc_id=${local.vpc_id}",
      " --kubeconfig <(aws ssm get-parameter --region ${var.region} --name ${aws_ssm_parameter.kubeconfig.name} --output text --query Parameter.Value --with-decryption) --context ${local.cluster_context}"
    ]))
    interpreter = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "test -d ${self.triggers.asdf_dir} || git clone https://github.com/asdf-vm/asdf.git ${self.triggers.asdf_dir} --branch v0.11.2 && export ASDF_DATA_DIR=$PWD/${self.triggers.asdf_dir} && . ${self.triggers.asdf_dir}/asdf.sh && for plugin in ${self.triggers.asdf_tools}; do asdf plugin add $plugin || test $? = 2; asdf install $plugin; done"
    interpreter = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "export ASDF_DATA_DIR=$PWD/${self.triggers.asdf_dir} && . ${self.triggers.asdf_dir}/asdf.sh && kubectl delete configmap -n flux-system cluster-vars --ignore-not-found --kubeconfig <(aws ssm get-parameter --region ${self.triggers.region} --name ${self.triggers.kubeconfig_parameter} --output text --query Parameter.Value --with-decryption) --context ${self.triggers.cluster_context}"
    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [
    null_resource.flux_bootstrap,
  ]
}
