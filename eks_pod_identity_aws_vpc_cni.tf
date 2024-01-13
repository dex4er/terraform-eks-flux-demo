## IRSA for VPC CNI addon

module "eks_pod_identity_aws_vpc_cni" {
  ## https://github.com/clowdhaus/terraform-aws-eks-pod-identity
  source = "github.com/clowdhaus/terraform-aws-eks-pod-identity"

  use_name_prefix    = false
  name               = "${module.eks.cluster_name}-pod-aws-vpc-cni"
  path               = "/"
  description        = "AWS VPC CNI IAM role"
  policy_name_prefix = "${module.eks.cluster_name}-pod-"

  ## See https://github.com/clowdhaus/terraform-aws-eks-pod-identity/issues/1
  # attach_aws_vpc_cni_policy = true
  # aws_vpc_cni_enable_ipv4   = true

  additional_policy_arns = {
    AmazonEKS_CNI_Policy = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  }

  tags = {
    Name   = "${var.cluster_name}-pod-aws-vpc-cni"
    Object = "module.eks_pod_identity_aws_vpc_cni"
  }
}
