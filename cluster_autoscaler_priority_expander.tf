## List of allowed node groups with priorities. Higher priority is more
## important.
##
## If new node group is created with the same prefix but different number
## then autoscaler prefers newer node group. It allows to do safe upgrade of
## the nodes in the cluster.

locals {
  ## https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/expander/priority/readme.md
  cluster_autoscaler_priorities = replace(yamlencode(transpose(
    {
      for kg, vg in local.node_groups : ("^${var.name}-node-group-${kg}$") => [try(regex("-(\\d+)$", kg), ["0"])[0]] if vg.create
    }
  )), "/(?m)^\"(\\d+)\":/", "$1:")
}

resource "null_resource" "cluster_autoscaler_priority_expander" {
  triggers = {
    asdf_dir                               = coalesce(var.asdf_dir, ".asdf-cluster_autoscaler_priority_expander")
    asdf_tools                             = "awscli kubectl"
    cluster_autoscaler_priorities_checksum = sha256(local.cluster_autoscaler_priorities)
    cluster_context                        = local.cluster_context
    kubeconfig_parameter                   = aws_ssm_parameter.kubeconfig.name
    region                                 = var.region
  }

  provisioner "local-exec" {
    command     = "test -d ${self.triggers.asdf_dir} || git clone https://github.com/asdf-vm/asdf.git ${self.triggers.asdf_dir} --branch v0.11.2 && . ${self.triggers.asdf_dir}/asdf.sh && for plugin in ${self.triggers.asdf_tools}; do asdf plugin add $plugin || test $? = 2; asdf install $plugin; done"
    interpreter = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    command     = ". ${self.triggers.asdf_dir}/asdf.sh && kubectl delete configmap -n kube-system cluster-autoscaler-priority-expander --ignore-not-found --kubeconfig <(aws ssm get-parameter --region ${var.region} --name ${aws_ssm_parameter.kubeconfig.name} --output text --query Parameter.Value --with-decryption) --context ${self.triggers.cluster_context} && kubectl create configmap -n kube-system cluster-autoscaler-priority-expander --from-literal=priorities=\"${local.cluster_context}\" --kubeconfig <(aws ssm get-parameter --region ${var.region} --name ${aws_ssm_parameter.kubeconfig.name} --output text --query Parameter.Value --with-decryption) --context ${local.cluster_context}"
    interpreter = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "test -d ${self.triggers.asdf_dir} || git clone https://github.com/asdf-vm/asdf.git ${self.triggers.asdf_dir} --branch v0.11.2 && . ${self.triggers.asdf_dir}/asdf.sh && for plugin in ${self.triggers.asdf_tools}; do asdf plugin add $plugin || test $? = 2; asdf install $plugin; done"
    interpreter = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    when        = destroy
    command     = ". ${self.triggers.asdf_dir}/asdf.sh && kubectl delete configmap -n kube-system cluster-autoscaler-priority-expander --kubeconfig <(aws ssm get-parameter --region ${self.triggers.region} --name ${self.triggers.kubeconfig_parameter} --output text --query Parameter.Value --with-decryption) --context ${self.triggers.cluster_context}"
    interpreter = ["/bin/bash", "-c"]
  }
}
