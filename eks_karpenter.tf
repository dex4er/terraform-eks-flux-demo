## AWS resources required by Karpenter

module "eks_karpenter" {
  ## https://github.com/terraform-aws-modules/terraform-aws-eks/tree/master/modules/karpenter
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.0"

  cluster_name = module.eks.cluster_name

  create_access_entry = false

  queue_name       = "${var.cluster_name}-karpenter"
  rule_name_prefix = "${substr(var.cluster_name, 0, 16)}-"

  create_iam_role          = true
  iam_role_use_name_prefix = false
  iam_role_name            = "${var.cluster_name}-karpenter"

  create_node_iam_role          = false
  node_iam_role_arn             = module.iam_role_node_group.iam_role_arn
  node_iam_role_use_name_prefix = false
  node_iam_role_name            = "${var.cluster_name}-karpenter"

  iam_policy_name        = "${var.cluster_name}-karpenter"
  iam_policy_description = "Karpenter IAM role for Pod Identity"

  tags = {
    Cluster = var.cluster_name
    Object  = "module.eks_karpenter"
  }
}

resource "aws_eks_pod_identity_association" "karpenter" {
  cluster_name    = var.cluster_name
  namespace       = "kube-system"
  service_account = "karpenter"
  role_arn        = module.eks_karpenter.iam_role_arn

  tags = {
    Cluster = var.cluster_name
    Object  = "aws_eks_pod_identity_association.karpenter"
  }
}
