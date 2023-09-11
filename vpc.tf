## VPC for the cluster. NAT gateway costs $37.96 monthly even if the cluster is
## scaled to zero!
##
## For demo purpose it might be better to run cluster in public network even if
## it is more risky.

module "vpc" {
  ## https://github.com/terraform-aws-modules/terraform-aws-vpc
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.1"

  name = var.cluster_name

  cidr = var.cidr

  ## To get predictable AZ use zone IDs rather than zone names
  azs = var.azs

  ## It is for private cluster with ELBs in public and master nodes in intra range
  public_subnets  = [cidrsubnet(var.cidr, 6, 11), cidrsubnet(var.cidr, 6, 12), cidrsubnet(var.cidr, 6, 13)]
  private_subnets = [cidrsubnet(var.cidr, 6, 21), cidrsubnet(var.cidr, 6, 22), cidrsubnet(var.cidr, 6, 23)]
  intra_subnets   = [cidrsubnet(var.cidr, 6, 31), cidrsubnet(var.cidr, 6, 32), cidrsubnet(var.cidr, 6, 33)]

  ## https://github.com/terraform-aws-modules/terraform-aws-vpc#nat-gateway-scenarios
  ## One NAT Gateway per subnet: we have single AZ node groups
  ## The first AZ will have NAT gateway
  enable_nat_gateway     = var.cluster_in_private_subnet ? true : false
  single_nat_gateway     = var.cluster_in_private_subnet ? true : false
  one_nat_gateway_per_az = false

  enable_dns_hostnames = true

  manage_default_network_acl    = true
  manage_default_route_table    = true
  manage_default_security_group = true

  default_network_acl_tags    = { Name = "${var.cluster_name}-default" }
  default_route_table_tags    = { Name = "${var.cluster_name}-default" }
  default_security_group_tags = { Name = "${var.cluster_name}-default" }

  ## https://aws.amazon.com/premiumsupport/knowledge-center/eks-vpc-subnet-discovery/
  public_subnet_tags = {
    Reach                                       = "public"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = 1
  }

  private_subnet_tags = {
    Reach                                       = "private"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = 1
  }

  intra_subnet_tags = {
    Reach = "intra"
  }

  tags = {
    Object = "module.vpc"
    VPC    = var.cluster_name
  }
}

locals {
  subnets_public_ids_by_azs  = { for i, v in var.azs : v => module.vpc.public_subnets[i] }
  subnets_private_ids_by_azs = { for i, v in var.azs : v => module.vpc.private_subnets[i] }
  subnets_ids_by_azs         = var.cluster_in_private_subnet ? local.subnets_private_ids_by_azs : local.subnets_public_ids_by_azs
}

output "vpc" {
  description = "Outputs from VPC module"
  value       = module.vpc
}
