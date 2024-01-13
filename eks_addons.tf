## Cluster addons.

locals {
  cluster_addons = {
    coredns = {
      ## https://docs.aws.amazon.com/eks/latest/userguide/managing-coredns.html
      version                     = "v1.10.1-eksbuild.6"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      configuration_values        = jsonencode(yamldecode(file("${path.module}/eks_addons/coredns.configuration.yaml")))
    }
    kube-proxy = {
      ## https://docs.aws.amazon.com/eks/latest/userguide/managing-kube-proxy.html
      version                     = "v1.27.8-eksbuild.4"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      configuration_values        = jsonencode(yamldecode(file("${path.module}/eks_addons/kube-proxy.configuration.yaml")))
    }
    vpc-cni = {
      ## https://docs.aws.amazon.com/eks/latest/userguide/managing-vpc-cni.html
      version                     = "v1.16.0-eksbuild.1"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      service_account_role_arn    = module.irsa_aws_vpc_cni.iam_role_arn
      configuration_values        = jsonencode(yamldecode(file("${path.module}/eks_addons/vpc-cni.configuration.yaml")))
    }
  }
}

resource "aws_eks_addon" "this" {
  for_each = local.cluster_addons

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
