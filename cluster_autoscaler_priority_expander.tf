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

resource "aws_ssm_parameter" "cluster_autoscaler_priorities" {
  name  = "${var.name}-cluster-autoscaler-priorities"
  type  = "String"
  value = local.cluster_autoscaler_priorities

  tags = {
    Name   = "${var.name}-cluster-autoscaler-priorities"
    Object = "aws_ssm_parameter.cluster-autoscaler-priorities"
  }
}

resource "null_resource" "cluster_autoscaler_priority_expander" {
  triggers = {
    cluster_autoscaler_priorities_checksum = sha256(local.cluster_autoscaler_priorities)
    cluster_context                        = local.cluster_context
  }

  provisioner "local-exec" {
    command     = "kubectl delete configmap -n kube-system cluster-autoscaler-priority-expander --ignore-not-found --kubeconfig .kube/config --context ${self.triggers.cluster_context} && kubectl create configmap -n kube-system cluster-autoscaler-priority-expander --from-literal=priorities=\"$(aws ssm get-parameter --name ${aws_ssm_parameter.cluster_autoscaler_priorities.name} --output text --query Parameter.Value)\" --kubeconfig .kube/config --context ${local.cluster_context}"
    interpreter = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete configmap -n kube-system cluster-autoscaler-priority-expander --kubeconfig .kube/config --context ${self.triggers.cluster_context}"
  }

  depends_on = [
    null_resource.aws_eks_update-kubeconfig_terraform,
  ]
}
