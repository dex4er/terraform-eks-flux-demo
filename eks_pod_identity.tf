## IAM role for cluster nodes shared between all node groups

locals {
  eks_pod_identity = {
    aws-lb-controller = {
      namespace       = "kube-system"
      service_account = "aws-load-balancer-controller"
      role_arn        = module.eks_pod_identity_aws_lb_controller.iam_role_arn
    }
    # default = {
    #   namespace       = "default"
    #   service_account = "default"
    #   additional_policy_arns = {
    #     AmazonS3FullAccess = "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    #   }
    # }
  }
}

module "iam_role_eks_pod_identity" {
  for_each = { for k, v in local.eks_pod_identity : k => v if lookup(v, "policy", null) != null || lookup(v, "additional_policy_arns", null) != null }

  ## https://github.com/terraform-aws-modules/terraform-aws-eks-pod-identity
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.2"

  use_name_prefix = false
  name            = "${var.cluster_name}-pod-${each.key}"
  path            = "/"
  description     = "EKS Cluster IAM role for pod indentity"

  attach_custom_policy    = lookup(each.value, "policy", null) != null
  source_policy_documents = lookup(each.value, "policy", null)
  additional_policy_arns  = lookup(each.value, "additional_policy_arns", null)

  tags = {
    Name   = "${var.cluster_name}-pod-${each.key}"
    Object = "module.iam_role_eks_pod_identity"
  }
}

resource "aws_eks_pod_identity_association" "eks_pod_identity" {
  for_each = local.eks_pod_identity

  cluster_name    = var.cluster_name
  namespace       = each.value.namespace
  service_account = each.value.service_account
  role_arn        = lookup(each.value, "role_arn", null) != null ? each.value.role_arn : module.iam_role_eks_pod_identity[each.key].iam_role_arn
}
