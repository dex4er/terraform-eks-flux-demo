## IRSA for cluster-autoscaler

module "irsa_cluster_autoscaler" {
  ## https://github.com/terraform-aws-modules/terraform-aws-iam/tree/master/modules/iam-role-for-service-accounts-eks
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.12"

  role_name          = "${module.eks.cluster_name}-irsa-cluster-autoscaler"
  role_path          = "/"
  role_description   = "Cluster autoscaler IAM role"
  policy_name_prefix = "${module.eks.cluster_name}-irsa-"

  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_ids   = [module.eks.cluster_name]

  oidc_providers = {
    (module.eks.cluster_name) = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:cluster-autoscaler"]
    }
  }

  tags = {
    Name   = "${var.name}-irsa-cluster-autoscaler"
    Object = "module.irsa_cluster_autoscaler"
  }
}
