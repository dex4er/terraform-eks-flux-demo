## For verification if we run this terraform with right privileges.

data "aws_caller_identity" "current" {}

locals {
  caller_identity   = data.aws_caller_identity.current.arn
  caller_role_parts = split("/", local.caller_identity)
  caller_role_name  = local.caller_role_parts[length(local.caller_role_parts) - 2]
  caller_role_arn   = "arn:aws:iam::${var.account_id}:role/${local.caller_role_name}"
}
