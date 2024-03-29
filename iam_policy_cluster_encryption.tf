## IAM Policy to allow to encrypt/decrypt a cluster.

module "iam_policy_cluster_encryption" {
  ## https://github.com/terraform-aws-modules/terraform-aws-iam/tree/master/modules/iam-policy
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 5.12"

  name        = "${var.cluster_name}-cluster-encryption"
  path        = "/"
  description = "${var.cluster_name} cluster encryption key IAM policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowEncryptDecrypt"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ListGrants",
          "kms:DescribeKey",
        ]
        Effect   = "Allow"
        Resource = ["arn:aws:kms:${var.region}:${var.account_id}:alias/${var.cluster_name}/${var.cluster_name}-cluster"]
      },
    ]
  })

  tags = {
    Name   = "${var.cluster_name}-cluster-encryption"
    Object = "module.iam_policy_cluster_encryption"
  }
}
