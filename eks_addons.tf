## Cluster addons.

locals {
  eks_addons = {
    coredns = {
      ## https://docs.aws.amazon.com/eks/latest/userguide/managing-coredns.html
      addon_version               = "v1.11.1-eksbuild.6"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      configuration_values        = jsonencode(yamldecode(file("${path.module}/eks_addons/coredns.configuration.yaml")))
    }
    eks-pod-identity-agent = {
      ## https://docs.aws.amazon.com/eks/latest/userguide/pod-id-agent-setup.html
      version                     = "v1.0.0-eksbuild.1"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      configuration_values        = jsonencode(yamldecode(file("${path.module}/eks_addons/eks-pod-identity-agent.configuration.yaml")))
    }
    kube-proxy = {
      ## https://docs.aws.amazon.com/eks/latest/userguide/managing-kube-proxy.html
      addon_version               = "v1.29.1-eksbuild.2"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      configuration_values        = jsonencode(yamldecode(file("${path.module}/eks_addons/kube-proxy.configuration.yaml")))
    }
    vpc-cni = {
      ## https://docs.aws.amazon.com/eks/latest/userguide/managing-vpc-cni.html
      addon_version               = "v1.16.4-eksbuild.2"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      service_account_role_arn    = module.irsa_aws_vpc_cni.iam_role_arn
      configuration_values        = jsonencode(yamldecode(file("${path.module}/eks_addons/vpc-cni.configuration.yaml")))
    }
  }
}
