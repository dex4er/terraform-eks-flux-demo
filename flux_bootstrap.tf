## It installs the FluxCD namespace. Prevents destroy to not accidentally
## delete everything installed by FluxCD.

resource "kubernetes_namespace_v1" "flux-system" {
  metadata {
    name = "flux-system"
  }

  lifecycle {
    ignore_changes = all
  }

  depends_on = [terraform_data.eks_is_ready]
}

## This ConfigMap is used to substitute variables used in Kustomizations.

resource "kubernetes_config_map_v1" "cluster-vars" {
  metadata {
    name      = "cluster-vars"
    namespace = kubernetes_namespace_v1.flux-system.metadata[0].name
  }

  data = {}

  lifecycle {
    ignore_changes = all
  }

  depends_on = [kubernetes_namespace_v1.flux-system]
}

resource "kubernetes_config_map_v1_data" "cluster-vars" {
  metadata {
    name      = kubernetes_config_map_v1.cluster-vars.metadata[0].name
    namespace = kubernetes_namespace_v1.flux-system.metadata[0].name
  }

  data = merge(
    {
      account_id        = var.account_id
      account_id_string = "\"${var.account_id}\""
    },
    { for i, v in var.azs :
      "azs_id_${i}" => v
    },
    { for i, v in var.azs :
      "azs_name_${i}" => data.aws_availability_zones.this[i].names[0]
    },
    {
      cluster_endpoint     = module.eks.cluster_endpoint
      cluster_name         = var.cluster_name
      cluster_subnet_reach = var.cluster_in_private_subnet ? "private" : "public"
      region               = var.region
      vpc_id               = local.vpc_id
    }
  )

  force = true

  depends_on = [kubernetes_config_map_v1.cluster-vars]
}

## It should be read-write Gitlab token used by FluxCD source-controller.

resource "kubernetes_secret_v1" "flux-system" {
  metadata {
    name      = "flux-system"
    namespace = kubernetes_namespace_v1.flux-system.metadata[0].name
  }

  data = {
    username = var.flux_git_repository_username
    password = var.flux_git_repository_password
  }

  type = "kubernetes.io/basic-auth"

  wait_for_service_account_token = false

  lifecycle {
    ignore_changes = [
      metadata,
    ]
  }

  depends_on = [kubernetes_namespace_v1.flux-system]
}

## The delay loop after secret is created

resource "time_sleep" "wait_for_flux_repo_credentials" {
  triggers = {
    resource_version = kubernetes_secret_v1.flux-system.metadata[0].resource_version
    uid              = kubernetes_secret_v1.flux-system.metadata[0].uid
  }

  create_duration = "1m"

  depends_on = [kubernetes_secret_v1.flux-system]
}

## Init Flux with kustomize override

resource "helm_release" "flux_operator" {
  name       = "flux-operator"
  namespace  = "flux-system"
  repository = "oci://ghcr.io/controlplaneio-fluxcd/charts"
  chart      = "flux-operator"
  version    = "0.10.0" ## $ crane ls ghcr.io/controlplaneio-fluxcd/charts/flux-operator | sort -r -V | grep '^[0-9]*\.' | head -n1

  values = [file("${path.module}/flux_operator.values.yaml")]

  depends_on = [
    kubernetes_config_map_v1_data.cluster-vars,
    time_sleep.wait_for_flux_repo_credentials,
  ]
}

resource "helm_release" "flux_instance" {
  name       = "flux"
  namespace  = "flux-system"
  repository = "oci://ghcr.io/controlplaneio-fluxcd/charts"
  chart      = "flux-instance"
  version    = "0.10.0" ## $ crane ls ghcr.io/controlplaneio-fluxcd/charts/flux-instance | sort -r -V | grep '^[0-9]*\.' | head -n1

  values = [file("${path.module}/flux_instance.values.yaml")]

  set {
    name  = "instance.sync.url"
    value = var.flux_git_repository_url
  }

  depends_on = [helm_release.flux_operator]
}
