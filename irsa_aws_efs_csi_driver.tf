## IRSA for aws-efs-csi-driver

module "irsa_aws_efs_csi_driver" {
  ## https://github.com/terraform-aws-modules/terraform-aws-iam/tree/master/modules/iam-role-for-service-accounts-eks
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.12"

  role_name          = "${module.eks.cluster_name}-irsa-aws-efs-csi-driver"
  role_path          = "/"
  role_description   = "AWS EFS CSI driver IAM role"
  policy_name_prefix = "${module.eks.cluster_name}-irsa-"

  attach_efs_csi_policy = true

  oidc_providers = {
    (module.eks.cluster_name) = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:efs-csi-controller", "kube-system:efs-csi-node"]
    }
  }

  tags = {
    Name   = "${var.cluster_name}-irsa-aws-vpc-cni"
    Object = "module.irsa_aws_efs_csi_driver"
  }
}
