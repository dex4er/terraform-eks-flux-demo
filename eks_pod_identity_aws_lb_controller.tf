## IRSA for AWS Load Balancer Controller

module "eks_pod_identity_aws_lb_controller" {
  ## https://github.com/clowdhaus/terraform-aws-eks-pod-identity
  source = "github.com/clowdhaus/terraform-aws-eks-pod-identity"

  use_name_prefix    = false
  name               = "${module.eks.cluster_name}-pod-aws-lb-controller"
  path               = "/"
  description        = "AWS Load Balancer Controller IAM role"
  policy_name_prefix = "${module.eks.cluster_name}-pod-"

  attach_aws_lb_controller_policy = true

  tags = {
    Name   = "${var.cluster_name}-pod-aws-lb-controller"
    Object = "module.eks_pod_identity_aws_lb_controller"
  }
}