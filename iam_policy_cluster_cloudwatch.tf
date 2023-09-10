## IAM Policy to deny to create CloudWatch by the cluster.
##
## After log group is destroyed by Terraform it forbids to recreate the same
## group by the cluster itself.

module "iam_policy_cluster_cloudwatch" {
  ## https://github.com/terraform-aws-modules/terraform-aws-iam/tree/master/modules/iam-policy
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 5.12"

  name        = "${var.cluster_name}-cluster-cloudwatch"
  path        = "/"
  description = "${var.cluster_name} cluster CloudWatch IAM policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyCreateLogGroup"
        Action   = ["logs:CreateLogGroup"]
        Effect   = "Deny"
        Resource = "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/eks/${var.cluster_name}/cluster:*"
      },
    ]
  })

  tags = {
    Name   = "${var.cluster_name}-cluster-cloudwatch"
    Object = "module.iam_policy_cluster_cloudwatch"
  }
}
