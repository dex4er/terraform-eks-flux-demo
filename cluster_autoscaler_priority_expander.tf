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
    cluster_autoscaler_priorities_checksum = sha256(local.cluster_autoscaler_priorities)
    cluster_context                        = local.cluster_context
    kubeconfig_parameter                   = aws_ssm_parameter.kubeconfig.name
  }

  provisioner "local-exec" {
    command     = "kubectl delete configmap -n kube-system cluster-autoscaler-priority-expander --ignore-not-found --kubeconfig <(aws ssm get-parameter --name ${aws_ssm_parameter.kubeconfig.name} --output text --query Parameter.Value --with-decryption) --context ${self.triggers.cluster_context} && kubectl create configmap -n kube-system cluster-autoscaler-priority-expander --from-literal=priorities=\"${local.cluster_context}\" --kubeconfig <(aws ssm get-parameter --name ${aws_ssm_parameter.kubeconfig.name} --output text --query Parameter.Value --with-decryption) --context ${local.cluster_context}"
    interpreter = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "kubectl delete configmap -n kube-system cluster-autoscaler-priority-expander --kubeconfig <(aws ssm get-parameter --name ${self.triggers.kubeconfig_parameter} --output text --query Parameter.Value --with-decryption) --context ${self.triggers.cluster_context}"
    interpreter = ["/bin/bash", "-c"]
  }
}
