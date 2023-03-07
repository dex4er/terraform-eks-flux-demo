data "aws_availability_zones" "this" {
  count = length(var.azs)

  filter {
    name   = "zone-id"
    values = [var.azs[count.index]]
  }
}

output "azs_names" {
  value = try(join(",", flatten(data.aws_availability_zones.this[*].names)), null)
}
