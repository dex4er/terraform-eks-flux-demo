## IAM role for a cluster

module "iam_role_cluster" {
  ## https://github.com/terraform-aws-modules/terraform-aws-iam/tree/master/modules/iam-assumable-role
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.12.0"

  role_name = "${var.name}-cluster"
  role_path = "/"

  role_description = "EKS Cluster node group IAM role"

  create_role       = true
  role_requires_mfa = false

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController",
    module.iam_policy_cluster_cloudwatch.arn,
    module.iam_policy_cluster_encryption.arn,
  ]

  trusted_role_services = ["eks.amazonaws.com"]

  force_detach_policies = true

  tags = {
    Name   = "${var.name}-cluster"
    Object = "module.iam_role_cluster"
  }
}
