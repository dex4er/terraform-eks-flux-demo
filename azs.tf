## AZs IDs are preferred than names because IDs are contant and names are
## shuffled for each account ID.
##
## To get the list of AZ IDs for current region, run:
## `aws ec2 describe-availability-zones --region $AWS_REGION`

data "aws_availability_zones" "this" {
  count = length(var.azs)

  filter {
    name   = "zone-id"
    values = [var.azs[count.index]]
  }
}

locals {
  azs_ids = flatten(data.aws_availability_zones.this[*].zone_ids)
}
