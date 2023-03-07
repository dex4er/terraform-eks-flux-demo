## Self-managed node group needs IAM instance profile

resource "aws_iam_instance_profile" "this" {
  for_each = { for k, v in local.node_groups : k => v if v.create }

  role = module.iam_role_node_group.iam_role_name

  name = "${var.name}-node-group-${each.key}"
  path = "/"

  tags = {
    Name      = "${var.name}-node-group-${each.key}"
    Cluster   = var.name
    NodeGroup = "${var.name}-node-group-${each.key}"
    Object    = "aws_iam_instance_profile.this"
  }
}
