## Cluster addons.

locals {
  eks_addons = {
    coredns = {
      ## https://docs.aws.amazon.com/eks/latest/userguide/managing-coredns.html
      ## $ aws eks describe-addon-versions --kubernetes-version 1.31 --addon-name coredns --query 'addons[].addonVersions[].{addonVersion:addonVersion,defaultVersion:compatibilities[0].defaultVersion}|[].addonVersion|[0]' --output text | cat
      addon_version               = "v1.11.3-eksbuild.1"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      configuration_values        = jsonencode(yamldecode(file("${path.module}/eks_addons/coredns.configuration.yaml")))
    }
    eks-pod-identity-agent = {
      ## https://docs.aws.amazon.com/eks/latest/userguide/pod-id-agent-setup.html
      ## $ aws eks describe-addon-versions --kubernetes-version 1.31 --addon-name eks-pod-identity-agent --query 'addons[].addonVersions[].{addonVersion:addonVersion,defaultVersion:compatibilities[0].defaultVersion}|[].addonVersion|[0]' --output text | cat
      version                     = "v1.3.2-eksbuild.2"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      configuration_values        = jsonencode(yamldecode(file("${path.module}/eks_addons/eks-pod-identity-agent.configuration.yaml")))
    }
    kube-proxy = {
      ## https://docs.aws.amazon.com/eks/latest/userguide/managing-kube-proxy.html
      ## $ aws eks describe-addon-versions --kubernetes-version 1.31 --addon-name kube-proxy --query 'addons[].addonVersions[].{addonVersion:addonVersion,defaultVersion:compatibilities[0].defaultVersion}|[].addonVersion|[0]' --output text | cat
      addon_version               = "v1.31.0-eksbuild.5"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      configuration_values        = jsonencode(yamldecode(file("${path.module}/eks_addons/kube-proxy.configuration.yaml")))
    }
    vpc-cni = {
      ## https://docs.aws.amazon.com/eks/latest/userguide/managing-vpc-cni.html
      ## $ aws eks describe-addon-versions --kubernetes-version 1.31 --addon-name vpc-cni --query 'addons[].addonVersions[].{addonVersion:addonVersion,defaultVersion:compatibilities[0].defaultVersion}|[].addonVersion|[0]' --output text | cat
      addon_version               = "v1.18.5-eksbuild.1"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      configuration_values        = jsonencode(yamldecode(file("${path.module}/eks_addons/vpc-cni.configuration.yaml")))
    }
  }
}
