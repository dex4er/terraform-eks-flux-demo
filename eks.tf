## EKS cluster

locals {
  ## https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html
  cluster_version = "1.31"

  ## https://docs.aws.amazon.com/eks/latest/APIReference/API_KubernetesNetworkConfigRequest.html
  cluster_service_cidr = "10.100.0.0/24"

  ## https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html
  cluster_enabled_log_types = ["audit", "api", "authenticator"]

  ## Number of days to retain log events
  cloudwatch_log_group_retention_in_days = 1
}

module "eks" {
  ## https://github.com/terraform-aws-modules/terraform-aws-eks
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name = var.cluster_name

  cluster_version = local.cluster_version

  vpc_id                    = local.vpc_id
  subnet_ids                = var.cluster_in_private_subnet ? module.vpc.private_subnets : module.vpc.public_subnets
  control_plane_subnet_ids  = module.vpc.intra_subnets
  cluster_service_ipv4_cidr = local.cluster_service_cidr

  cluster_ip_family               = "ipv4"
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  create_cluster_primary_security_group_tags = false
  create_cluster_security_group              = false
  cluster_security_group_id                  = module.sg_cluster.security_group_id
  create_node_security_group                 = false
  node_security_group_id                     = module.sg_node_group.security_group_id

  create_iam_role = false
  iam_role_arn    = module.iam_role_cluster.iam_role_arn

  create_cloudwatch_log_group            = true
  cluster_enabled_log_types              = local.cluster_enabled_log_types
  cloudwatch_log_group_retention_in_days = local.cloudwatch_log_group_retention_in_days

  create_kms_key = false

  cluster_encryption_config = {
    provider_key_arn = module.kms_cluster.key_arn
    resources        = ["secrets"]
  }

  authentication_mode = "API"
  access_entries      = local.access_entries

  eks_managed_node_group_defaults = local.eks_managed_node_group_defaults
  eks_managed_node_groups         = local.eks_node_groups

  cluster_addons = local.eks_addons

  tags = {
    Name    = var.cluster_name
    Cluster = var.cluster_name
    Object  = "module.eks"
  }
}

locals {
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
}

output "eks" {
  description = "Outputs from EKS module"
  value       = module.eks
}
