## Generates kubeconfig. Uses granted if it is installed. Terraform uses only
## ./kube directory. Config in home directory is for CLI usage.

locals {
  cluster_context = "arn:aws:eks:${var.region}:${var.account_id}:cluster/${var.name}"
}

## ~/.kube/config

resource "null_resource" "aws_eks_update-kubeconfig_home" {
  triggers = {
    cluster_context = local.cluster_context
  }

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region} && if command -v assumego >/dev/null 2>&1; then kubectl config set-credentials ${local.cluster_context} --exec-command=assumego --exec-arg=$AWS_PROFILE --exec-arg=--exec --exec-arg='aws --region ${var.region} eks get-token --cluster-name ${var.name} --role ${var.assume_role}' --exec-env=GRANTED_QUIET=true --exec-env=FORCE_NO_ALIAS=true --exec-env=AWS_PROFILE-; fi"
  }
}

## ./.kube/config

resource "null_resource" "aws_eks_update-kubeconfig_terraform" {
  triggers = {
    cluster_context = local.cluster_context
  }

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region} --kubeconfig ./.kube/config && if command -v assumego >/dev/null 2>&1; then kubectl config set-credentials ${local.cluster_context} --exec-command=assumego --exec-arg=$AWS_PROFILE --exec-arg=--exec --exec-arg='aws --region ${var.region} eks get-token --cluster-name ${var.name} --role ${var.assume_role}' --exec-env=GRANTED_QUIET=true --exec-env=FORCE_NO_ALIAS=true --exec-env=AWS_PROFILE- --kubeconfig ./.kube/config; fi"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ./.kube/config"
  }
}
