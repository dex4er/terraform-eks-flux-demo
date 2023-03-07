## ~/.kube/config

resource "null_resource" "aws_eks_update-kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${var.name} --region ${var.region} && if command -v assumego >/dev/null 2>&1; then kubectl config set-credentials arn:aws:eks:${var.region}:${var.account_id}:cluster/${var.name} --exec-command=assumego --exec-arg=$AWS_PROFILE --exec-arg=--exec --exec-arg='aws --region ${var.region} eks get-token --cluster-name ${var.name} --role ${var.assume_role}' --exec-env=GRANTED_QUIET=true --exec-env=FORCE_NO_ALIAS=true --exec-env=AWS_PROFILE-; fi"
  }

  depends_on = [
    module.eks,
  ]
}

## ./.kube/config

resource "null_resource" "aws_eks_update-kubeconfig_kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${var.name} --region ${var.region} --kubeconfig ./.kube/config && if command -v assumego >/dev/null 2>&1; then kubectl config set-credentials arn:aws:eks:${var.region}:${var.account_id}:cluster/${var.name} --exec-command=assumego --exec-arg=$AWS_PROFILE --exec-arg=--exec --exec-arg='aws --region ${var.region} eks get-token --cluster-name ${var.name} --role ${var.assume_role}' --exec-env=GRANTED_QUIET=true --exec-env=FORCE_NO_ALIAS=true --exec-env=AWS_PROFILE- --kubeconfig ./.kube/config; fi"
  }

  depends_on = [
    module.eks,
  ]
}
