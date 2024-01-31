## Persistent ALB for cluster ingress.

## Note: This is a special setup when this ALB is a part of a larger
## networking configuration, ie. the ALB is a Target Group in an another LB.
##
## It that case we need to make sure that ALB for ingress is persistent
## and not created and removed dynamically by AWS Load Balancer Controller.

resource "aws_lb" "ingress" {
  name               = "${var.cluster_name}-ingress"
  load_balancer_type = "application"

  subnets         = module.vpc.public_subnets
  security_groups = [module.vpc.default_security_group_id]

  ## check alb.ingress.kubernetes.io/scheme (internal: true, internet-facing: false)
  internal = false

  ## check alb.ingress.kubernetes.io/ip-address-type (ipv4, dualstack)
  ip_address_type = "ipv4"

  preserve_host_header = false

  ## All tags must be the same as created by aws-load-balancer-controller

  tags = {
    ManagedBy                                   = "AWS Load Balancer Controller"
    "elbv2.k8s.aws/cluster"                     = var.cluster_name
    "ingress.k8s.aws/resource"                  = "LoadBalancer"
    "ingress.k8s.aws/stack"                     = "${var.cluster_name}-ingress"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }

  ## Security groups are managed by AWS Load Balancer Controller
  ## then must be ignored by Terraform.

  lifecycle {
    ignore_changes = [security_groups]
  }
}

resource "aws_lb_listener" "http-80" {
  load_balancer_arn = aws_lb.ingress.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    order = 1
    type  = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      status_code  = "404"
    }
  }

  tags = {
    ManagedBy                                   = "AWS Load Balancer Controller"
    "elbv2.k8s.aws/cluster"                     = var.cluster_name
    "ingress.k8s.aws/resource"                  = "80"
    "ingress.k8s.aws/stack"                     = "${var.cluster_name}-ingress"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

output "alb_ingress_arn" {
  description = "ARN of ALB"
  value       = aws_lb.ingress.arn
}

## Target Group makes ALB persistent: it cannot be removed until the target
## registered.

resource "aws_lb_target_group" "ingress" {
  name        = aws_lb.ingress.name
  target_type = "alb"
  port        = aws_lb_listener.http-80.port
  protocol    = "TCP"
  vpc_id      = aws_lb.ingress.vpc_id
}

resource "aws_lb_target_group_attachment" "ingress" {
  target_group_arn = aws_lb_target_group.ingress.arn
  target_id        = aws_lb.ingress.arn
  port             = aws_lb_listener.http-80.port
}

output "lb_target_group_ingress_arn" {
  description = "ARN of ALB"
  value       = aws_lb_target_group.ingress.arn
}
