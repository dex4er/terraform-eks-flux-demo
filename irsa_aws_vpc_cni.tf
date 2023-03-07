## IRSA for VPC CNI addon

module "irsa_aws_vpc_cni" {
  ## https://github.com/terraform-aws-modules/terraform-aws-iam/tree/master/modules/iam-role-for-service-accounts-eks
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.11.2"

  role_name          = "${module.eks.cluster_name}-irsa-aws-vpc-cni"
  role_path          = "/"
  role_description   = "AWS VPC CNI IAM role"
  policy_name_prefix = "${module.eks.cluster_name}-irsa-"

  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    (module.eks.cluster_name) = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }

  tags = {
    Name   = "${var.name}-irsa-aws-vpc-cni"
    Object = "module.irsa_aws_vpc_cni"
  }
}
