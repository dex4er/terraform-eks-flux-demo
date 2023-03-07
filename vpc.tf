## VPC with three subnetworks

module "vpc" {
  ## https://github.com/terraform-aws-modules/terraform-aws-vpc
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.19.0"

  name = var.name

  cidr = "10.99.0.0/18"

  ## To get predictable AZ use zone IDs rather than zone names
  azs = var.azs

  ## It is for private cluster with ELBs in public and master nodes in intra range
  public_subnets  = ["10.99.0.0/24", "10.99.1.0/24", "10.99.2.0/24"]
  private_subnets = ["10.99.3.0/24", "10.99.4.0/24", "10.99.5.0/24"]
  intra_subnets   = ["10.99.6.0/24", "10.99.7.0/24", "10.99.8.0/24"]

  ## https://github.com/terraform-aws-modules/terraform-aws-vpc#nat-gateway-scenarios
  ## One NAT Gateway per subnet: we have single AZ node groups
  ## The first AZ will have NAT gateway
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  enable_dns_hostnames = true

  manage_default_network_acl    = true
  manage_default_route_table    = true
  manage_default_security_group = true

  default_network_acl_tags    = { Name = "${var.name}-default" }
  default_route_table_tags    = { Name = "${var.name}-default" }
  default_security_group_tags = { Name = "${var.name}-default" }

  intra_subnet_tags = {
    Reach = "intra"
  }

  ## https://aws.amazon.com/premiumsupport/knowledge-center/eks-vpc-subnet-discovery/
  public_subnet_tags = {
    Reach                               = "public"
    "kubernetes.io/cluster/${var.name}" = "shared"
    "kubernetes.io/role/elb"            = 1
  }

  private_subnet_tags = {
    Reach                               = "private"
    "kubernetes.io/cluster/${var.name}" = "shared"
    "kubernetes.io/role/internal-elb"   = 1
  }

  tags = {
    Object = "module.vpc"
    VPC    = var.name
  }
}

locals {
  subnets_private_ids_by_azs = { for i, v in var.azs : v => module.vpc.private_subnets[i] }
}

output "subnets_private_ids_by_azs" {
  value = try(join(",", [for k, v in local.subnets_private_ids_by_azs : "${k}=${local.subnets_private_ids_by_azs[k]}"]), null)
}
