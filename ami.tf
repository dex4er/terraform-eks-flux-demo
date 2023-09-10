## Find out AMIs for node groups

data "aws_ami" "eks_node_group" {
  for_each = { for k, v in local.node_groups : k => v if lookup(v, "ami_name", null) != null }

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
