## Find out AMIs for node groups

data "aws_ami" "eks_node_group" {
  for_each = local.node_groups

  most_recent = true

  owners = [each.value.ami_owner]

  filter {
    name   = "name"
    values = [each.value.ami_name]
  }

  filter {
    name   = "architecture"
    values = [each.value.ami_architecture]
  }
}
