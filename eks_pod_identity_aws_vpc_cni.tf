## IRSA for VPC CNI addon

module "eks_pod_identity_aws_vpc_cni" {
  ## https://github.com/terraform-aws-modules/terraform-aws-eks-pod-identity
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.2"

  use_name_prefix    = false
  name               = "${module.eks.cluster_name}-pod-aws-vpc-cni"
  path               = "/"
  description        = "AWS VPC CNI IAM role"
  policy_name_prefix = "${module.eks.cluster_name}-pod-"

  attach_aws_vpc_cni_policy = true
  aws_vpc_cni_enable_ipv4   = true

  tags = {
    Name   = "${var.cluster_name}-pod-aws-vpc-cni"
    Object = "module.eks_pod_identity_aws_vpc_cni"
  }
}
