## Cluster addons.

locals {
  cluster_addons = {
    coredns = {
      ## https://docs.aws.amazon.com/eks/latest/userguide/managing-coredns.html
      version                     = "v1.9.3-eksbuild.6"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
    kube-proxy = {
      ## https://docs.aws.amazon.com/eks/latest/userguide/managing-kube-proxy.html
      version                     = "v1.24.15-minimal-eksbuild.2"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
    vpc-cni = {
      ## https://docs.aws.amazon.com/eks/latest/userguide/managing-vpc-cni.html
      version                     = "v1.14.0-eksbuild.3"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      service_account_role_arn    = module.irsa_aws_vpc_cni.iam_role_arn
    }
  }
}

resource "aws_eks_addon" "this" {
  for_each = local.cluster_addons

  cluster_name = module.eks.cluster_name
  addon_name   = each.key

  addon_version               = each.value.version
  resolve_conflicts_on_create = lookup(each.value, "resolve_conflicts_on_create", null)
  resolve_conflicts_on_update = lookup(each.value, "resolve_conflicts_on_update", null)
  service_account_role_arn    = lookup(each.value, "service_account_role_arn", null)

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
