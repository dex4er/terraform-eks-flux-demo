## Service linked role for cluster autoscaler

resource "aws_iam_service_linked_role" "autoscaling" {
  aws_service_name = "autoscaling.amazonaws.com"
  custom_suffix    = var.cluster_name
  description      = "Allows EC2 Auto Scaling to use or manage AWS services and resources on your behalf."

  tags = {
    Name   = "AWSServiceRoleForAutoScaling_${var.cluster_name}"
    Object = "aws_iam_service_linked_role.autoscaling"
  }
}

## Additional time for IAM propagation

resource "time_sleep" "iam_service_role_autoscaling" {
  create_duration = "1m"

  triggers = {
    arn = aws_iam_service_linked_role.autoscaling.arn
  }
}

locals {
  service_linked_role_arn = time_sleep.iam_service_role_autoscaling.triggers.arn
}
