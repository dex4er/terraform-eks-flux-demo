## Security Group for nodes

module "sg_node_group" {
  ## https://github.com/terraform-aws-modules/terraform-aws-security-group
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.17.1"

  name = "${var.name}-node-group"

  use_name_prefix = false

  description = "EKS node shared security group"
  vpc_id      = local.vpc_id

  ingress_with_source_security_group_id = [
    {
      description              = "Cluster API to node groups"
      rule                     = "https-443-tcp"
      source_security_group_id = module.sg_cluster.security_group_id
    },
    {
      description              = "Cluster API to node kubelets"
      from_port                = 10250
      to_port                  = 10250
      protocol                 = "tcp"
      source_security_group_id = module.sg_cluster.security_group_id
    },
    {
      description              = "Cluster API to Nodegroup all traffic"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      source_security_group_id = module.sg_cluster.security_group_id
    },
  ]

  ingress_with_self = [
    {
      description = "Node to node CoreDNS"
      rule        = "dns-tcp"
    },
    {
      description = "Node to node CoreDNS"
      rule        = "dns-udp"
    },
    {
      description = "Node to node all ports/protocols"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
    },
  ]

  egress_with_source_security_group_id = [
    {
      description              = "Node groups to cluster API"
      rule                     = "https-443-tcp"
      source_security_group_id = module.sg_cluster.security_group_id
    },
  ]

  egress_with_self = [
    {
      description = "Node to node CoreDNS"
      rule        = "dns-tcp"
    },
    {
      description = "Node to node CoreDNS"
      rule        = "dns-udp"
    },
  ]

  egress_with_cidr_blocks = [
    {
      description = "Egress all HTTPS to internet"
      rule        = "https-443-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      description = "Egress NTP/TCP to internet"
      from_port   = 123
      to_port     = 123
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      description = "Egress NTP/TCP to internet"
      rule        = "ntp-udp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      description = "Node all egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  tags = {
    Name   = "${var.name}-node-group"
    Object = "module.sg_node_group"
  }
}
