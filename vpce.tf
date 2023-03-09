## Endpoint services for private network to avoid communication with AWS APIs
## via NAT gateway

module "vpce" {
  ## https://github.com/terraform-aws-modules/terraform-aws-vpc/tree/master/modules/vpc-endpoints
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "3.19.0"

  vpc_id             = local.vpc_id
  security_group_ids = [module.sg_vpce.security_group_id]
  subnet_ids         = module.vpc.private_subnets

  endpoints = merge({
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
      tags = {
        Name = "${var.name}-s3"
      }
    }
    },
    { for service in toset(["autoscaling", "ecr.api", "ecr.dkr", "ec2", "ec2messages", "elasticloadbalancing", "sts", "kms", "logs", "ssm", "ssmmessages"]) :
      replace(service, ".", "_") =>
      {
        service             = service
        private_dns_enabled = true
        tags                = { Name = "${var.name}-${replace(service, ".", "-")}" }
      }
  })

  tags = {
    Name   = var.name
    Object = "module.vpce"
    VPC    = var.name
    Reach  = "private"
  }
}
