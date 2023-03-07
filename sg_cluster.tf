## Security Group for a cluster

module "sg_cluster" {
  ## https://github.com/terraform-aws-modules/terraform-aws-security-group
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.17.1"

  name = "${var.name}-cluster"

  use_name_prefix = false

  description = "EKS cluster security group"
  vpc_id      = local.vpc_id

  ingress_with_source_security_group_id = [
    {
      description              = "Node groups to cluster API"
      rule                     = "https-443-tcp"
      source_security_group_id = module.sg_node_group.security_group_id
    },
  ]

  egress_with_source_security_group_id = [
    {
      description              = "Cluster API to node groups"
      rule                     = "https-443-tcp"
      source_security_group_id = module.sg_node_group.security_group_id
    },
    {
      description              = "Cluster API to node kubelets"
      from_port                = 10250
      to_port                  = 10250
      protocol                 = "tcp"
      source_security_group_id = module.sg_node_group.security_group_id
    },
  ]

  tags = {
    Name   = "${var.name}-cluster"
    Object = "module.sg_cluster"
  }
}
