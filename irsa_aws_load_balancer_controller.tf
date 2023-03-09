## IRSA for AWS Load Balancer Controller

module "irsa_aws_load_balancer_controller" {
  ## https://github.com/terraform-aws-modules/terraform-aws-iam/tree/master/modules/iam-role-for-service-accounts-eks
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.12.0"

  role_name          = "${module.eks.cluster_name}-irsa-aws-load-balancer-controller"
  role_path          = "/"
  role_description   = "AWS Load Balancer Controller IAM role"
  policy_name_prefix = "${module.eks.cluster_name}-irsa-"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    (module.eks.cluster_name) = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = {
    Name   = "${var.name}-irsa-aws-load-balancer-controller"
    Object = "module.irsa_aws_load_balancer_controller"
  }
}
