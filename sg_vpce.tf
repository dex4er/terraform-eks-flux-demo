module "sg_vpce" {
  ## https://github.com/terraform-aws-modules/terraform-aws-security-group
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.17.1"

  use_name_prefix = false
  name            = "${var.name}-vpce"

  description = "Security group for VPC endpoint access"
  vpc_id      = local.vpc_id

  ingress_with_cidr_blocks = [
    {
      description = "VPC private CIDR HTTPS"
      rule        = "https-443-tcp"
      cidr_blocks = join(",", module.vpc.private_subnets_cidr_blocks)
    },
  ]

  egress_with_cidr_blocks = [
    {
      description = "All egress HTTPS"
      rule        = "https-443-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  tags = {
    Name   = "${var.name}-vpce"
    Object = "module.sg_vpce"
  }
}
