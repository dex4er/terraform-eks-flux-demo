## Cluster addons.

locals {
  cluster_addons = {
    coredns = {
      ## https://docs.aws.amazon.com/eks/latest/userguide/managing-coredns.html
      version                     = "v1.9.3-eksbuild.6"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      configuration_values        = jsonencode(yamldecode(file("${path.module}/eks_addons/coredns.configuration.yaml")))
    }
    kube-proxy = {
      ## https://docs.aws.amazon.com/eks/latest/userguide/managing-kube-proxy.html
      version                     = "v1.25.11-eksbuild.2"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      configuration_values        = jsonencode(yamldecode(file("${path.module}/eks_addons/kube-proxy.configuration.yaml")))
    }
  }
}

resource "aws_eks_addon" "this" {
  for_each = { for k, v in local.cluster_addons : k => v if !try(v.before_compute, false) }

  cluster_name                = module.eks.cluster_name
  addon_name                  = each.key
  addon_version               = each.value.version
  resolve_conflicts_on_create = lookup(each.value, "resolve_conflicts_on_create", null)
  resolve_conflicts_on_update = lookup(each.value, "resolve_conflicts_on_update", null)
  service_account_role_arn    = lookup(each.value, "service_account_role_arn", null)
  configuration_values        = lookup(each.value, "configuration_values", null)
  preserve                    = true

  tags = {
    Name         = "${var.cluster_name}-addon-${each.key}"
    Cluster      = var.cluster_name
    ClusterAddon = each.key
    Object       = "aws_eks_addon.this"
  }

  depends_on = [
    ## CoreDNS requires at least single node running
    time_sleep.eks_default_node_group_delay,
  ]
}

resource "aws_eks_addon" "before_compute" {
  for_each = { for k, v in local.cluster_addons : k => v if try(v.before_compute, false) }

  cluster_name                = module.eks.cluster_name
  addon_name                  = each.key
  addon_version               = each.value.version
  resolve_conflicts_on_create = lookup(each.value, "resolve_conflicts_on_create", null)
  resolve_conflicts_on_update = lookup(each.value, "resolve_conflicts_on_update", null)
  service_account_role_arn    = lookup(each.value, "service_account_role_arn", null)
  configuration_values        = lookup(each.value, "configuration_values", null)
  preserve                    = true

  tags = {
    Name         = "${var.cluster_name}-addon-${each.key}"
    Cluster      = var.cluster_name
    ClusterAddon = each.key
    Object       = "aws_eks_addon.before_compute"
  }
}
