## IRSA for Amazon EFS CSI Driver

module "irsa_aws_efs_csi_controller" {
  ## https://github.com/terraform-aws-modules/terraform-aws-iam/tree/master/modules/iam-role-for-service-accounts-eks
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.12"

  role_name          = "${module.eks.cluster_name}-irsa-aws-efs-csi-controller"
  role_path          = "/"
  role_description   = "Amazon EFS CSI Driver controller IAM role in ${var.cluster_name} cluster"
  policy_name_prefix = "${module.eks.cluster_name}-irsa-"

  attach_efs_csi_policy = true

  oidc_providers = {
    (module.eks.cluster_name) = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:efs-csi-controller"]
    }
  }

  tags = {
    Name   = "${var.cluster_name}-irsa-aws-efs-csi-controller"
    Object = "module.irsa_aws_efs_csi_controller"
  }
}

data "aws_iam_policy_document" "iam_policy_aws_efs_csi_node" {
  statement {
    sid    = "AllowEFSMountAccess"
    effect = "Allow"

    resources = [
      module.efs["dynamic"].arn,
      module.efs["static"].arn,
    ]

    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientRootAccess",
      "elasticfilesystem:ClientWrite",
    ]

    condition {
      test     = "Bool"
      variable = "elasticfilesystem:AccessedViaMountTarget"
      values   = ["true"]
    }
  }
}

module "iam_policy_aws_efs_csi_node" {
  ## https://github.com/terraform-aws-modules/terraform-aws-iam/tree/master/modules/iam-policy
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 5.28"

  name_prefix = "${module.eks.cluster_name}-irsa-aws-efs-csi-node-"
  description = "IAM policy for Amazon EFS CSI Driver node IAM role in ${var.cluster_name} cluster"

  policy = data.aws_iam_policy_document.iam_policy_aws_efs_csi_node.json

  tags = {
    Name   = "${module.eks.cluster_name}-irsa-aws-efs-csi-node"
    Object = "module.iam_policy_aws_efs_csi_node"
  }
}

module "irsa_aws_efs_csi_node" {
  ## https://github.com/terraform-aws-modules/terraform-aws-iam/tree/master/modules/iam-role-for-service-accounts-eks
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.12"

  role_name          = "${module.eks.cluster_name}-irsa-aws-efs-csi-node"
  role_path          = "/"
  role_description   = "AWS EFS CSI node IAM role in ${var.cluster_name} cluster"
  policy_name_prefix = "${module.eks.cluster_name}-irsa-"

  role_policy_arns = {
    policy = module.iam_policy_aws_efs_csi_node.arn
  }

  oidc_providers = {
    (module.eks.cluster_name) = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:efs-csi-node"]
    }
  }

  tags = {
    Name   = "${var.cluster_name}-aws-efs-csi-driver"
    Object = "module.irsa_aws_efs_csi_node"
  }
}
