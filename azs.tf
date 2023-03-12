## AZs IDs are preferred than names because IDs are contant and names are
## shuffled for each account ID.

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
