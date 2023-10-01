module "efs" {
  ## https://github.com/terraform-aws-modules/terraform-aws-efs
  source  = "terraform-aws-modules/efs/aws"
  version = "~> 1.3"

  for_each = toset(["dynamic", "static"])

  name           = "${var.cluster_name}-${each.key}"
  creation_token = "${var.cluster_name}-${each.key}"
  encrypted      = true

  mount_targets = { for k, v in zipmap(var.azs, module.vpc.public_subnets) : k => { subnet_id = v } }

  security_group_name        = "${var.cluster_name}-efs-${each.key}"
  security_group_description = "EFS security group ${each.key}"
  security_group_vpc_id      = module.vpc.vpc_id
  security_group_rules = {
    vpc = {
      description = "NFS ingress from VPC public subnets"
      cidr_blocks = module.vpc.public_subnets_cidr_blocks
    }
  }

  enable_backup_policy = false

  tags = {
    Name   = "${var.cluster_name}-${each.key}"
    Object = "module.efs"
  }
}

output "efs" {
  description = "Outputs from EFS module"
  value       = module.efs
}
