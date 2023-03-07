## For verification if we run this terraform with right privileges.

data "aws_caller_identity" "current" {}

locals {
  caller_identity = data.aws_caller_identity.current.arn
}

output "caller_identity" {
  value = local.caller_identity
}
