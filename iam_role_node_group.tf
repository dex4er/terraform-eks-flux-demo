## IAM role for cluster nodes shared between all node groups

module "iam_role_node_group" {
  ## https://github.com/terraform-aws-modules/terraform-aws-iam/tree/master/modules/iam-assumable-role
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 5.12"

  role_name = "${var.cluster_name}-node-group"
  role_path = "/"

  role_description = "EKS Cluster node group IAM role"

  create_role       = true
  role_requires_mfa = false

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
  ]

  trusted_role_services = ["ec2.amazonaws.com"]

  force_detach_policies = true

  tags = {
    Name   = "${var.cluster_name}-node-group"
    Object = "module.iam_role_node_group"
  }
}
