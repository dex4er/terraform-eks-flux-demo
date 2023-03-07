## Cluster addons.

locals {
  cluster_addons = {
    coredns = {
      ## https://docs.aws.amazon.com/eks/latest/userguide/managing-coredns.html
      version           = "v1.8.7-eksbuild.4"
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {
      ## https://docs.aws.amazon.com/eks/latest/userguide/managing-kube-proxy.html
      version           = "v1.24.7-eksbuild.2"
      resolve_conflicts = "OVERWRITE"
    }
    vpc-cni = {
      ## https://docs.aws.amazon.com/eks/latest/userguide/managing-vpc-cni.html
      version                  = "v1.12.2-eksbuild.1"
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = module.irsa_aws_vpc_cni.iam_role_arn
    }
  }
}

resource "aws_eks_addon" "this" {
  for_each = local.cluster_addons

  cluster_name = module.eks.cluster_name
  addon_name   = each.key

  addon_version            = each.value.version
  resolve_conflicts        = lookup(each.value, "resolve_conflicts", null)
  service_account_role_arn = lookup(each.value, "service_account_role_arn", null)

  tags = {
    Name         = "${var.name}-addon-${each.key}"
    Cluster      = var.name
    ClusterAddon = each.key
    Object       = "aws_eks_addon.this"
  }

  depends_on = [
    ## CoreDNS requires at least single node running
    time_sleep.eks_default_node_group_delay,
  ]
}
