## Cluster addons.

locals {
  cluster_addons_variables = merge(
    {
      cluster_name = var.cluster_name
      region       = var.region
    }
  )

  eks_addons = {
    coredns = {
      ## https://docs.aws.amazon.com/eks/latest/userguide/managing-coredns.html
      ## $ aws eks describe-addon-versions --kubernetes-version 1.31 --addon-name coredns --query 'addons[].addonVersions[].{addonVersion:addonVersion,defaultVersion:compatibilities[0].defaultVersion}|[].addonVersion|[0]' --output text | cat
      addon_version               = "v1.11.3-eksbuild.2"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      configuration_values        = trimsuffix(templatefile("${path.module}/eks_addons/coredns.configuration.yaml", local.cluster_addons_variables), "\n")
    }
    eks-pod-identity-agent = {
      ## https://docs.aws.amazon.com/eks/latest/userguide/pod-id-agent-setup.html
      ## $ aws eks describe-addon-versions --kubernetes-version 1.31 --addon-name eks-pod-identity-agent --query 'addons[].addonVersions[].{addonVersion:addonVersion,defaultVersion:compatibilities[0].defaultVersion}|[].addonVersion|[0]' --output text | cat
      version                     = "v1.3.4-eksbuild.1"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      configuration_values        = trimsuffix(templatefile("${path.module}/eks_addons/eks-pod-identity-agent.configuration.yaml", local.cluster_addons_variables), "\n")
      before_compute              = true
    }
    kube-proxy = {
      ## https://docs.aws.amazon.com/eks/latest/userguide/managing-kube-proxy.html
      ## $ aws eks describe-addon-versions --kubernetes-version 1.31 --addon-name kube-proxy --query 'addons[].addonVersions[].{addonVersion:addonVersion,defaultVersion:compatibilities[0].defaultVersion}|[].addonVersion|[0]' --output text | cat
      addon_version               = "v1.31.3-eksbuild.2"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      configuration_values        = trimsuffix(templatefile("${path.module}/eks_addons/kube-proxy.configuration.yaml", local.cluster_addons_variables), "\n")
      before_compute              = true
    }
    vpc-cni = {
      ## https://docs.aws.amazon.com/eks/latest/userguide/managing-vpc-cni.html
      ## $ aws eks describe-addon-versions --kubernetes-version 1.31 --addon-name vpc-cni --query 'addons[].addonVersions[].{addonVersion:addonVersion,defaultVersion:compatibilities[0].defaultVersion}|[].addonVersion|[0]' --output text | cat
      addon_version               = "v1.19.0-eksbuild.1"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      service_account_role_arn    = module.eks_pod_identity_aws_vpc_cni.iam_role_arn
      configuration_values        = trimsuffix(templatefile("${path.module}/eks_addons/vpc-cni.configuration.yaml", local.cluster_addons_variables), "\n")
      pod_identity_association = [{
        role_arn        = module.eks_pod_identity_aws_vpc_cni.iam_role_arn
        service_account = "aws-node"
      }]
      before_compute = true
    }
  }
}
