## Install main Flux kustomization.

resource "null_resource" "flux_kustomization_all" {
  triggers = {
    asdf_dir                      = coalesce(var.asdf_dir, ".asdf-flux_kustomization_all")
    asdf_tools                    = "awscli flux2 kubectl"
    cluster_context               = local.cluster_context
    kubeconfig_parameter          = aws_ssm_parameter.kubeconfig.name
    kustomization_to_remove_later = "aws-load-balancer-controller"
    region                        = var.region
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/asdf_install.sh"
    environment = {
      asdf_dir   = self.triggers.asdf_dir
      asdf_tools = self.triggers.asdf_tools
    }
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/flux_kustomization_all.sh"
    environment = {
      asdf_dir             = self.triggers.asdf_dir
      cluster_context      = self.triggers.cluster_context
      kubeconfig_parameter = self.triggers.kubeconfig_parameter
      region               = self.triggers.region
    }
  }

  ## Safe uninstalling of flux: 1. standard workloads; 2. controllers; 3. flux

  provisioner "local-exec" {
    when    = destroy
    command = "bash ${path.module}/asdf_install.sh"
    environment = {
      asdf_dir   = self.triggers.asdf_dir
      asdf_tools = self.triggers.asdf_tools
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "bash ${path.module}/flux_kustomization_all_destroy.sh"
    environment = {
      asdf_dir                      = self.triggers.asdf_dir
      cluster_context               = self.triggers.cluster_context
      kubeconfig_parameter          = self.triggers.kubeconfig_parameter
      kustomization_to_remove_later = self.triggers.kustomization_to_remove_later
      region                        = self.triggers.region
    }
  }


  depends_on = [
    ## Most of the dependencies here are for correct order on destroy
    module.iam_role_cluster,
    module.iam_role_node_group,
    module.irsa_aws_load_balancer_controller,
    module.irsa_aws_vpc_cni,
    module.irsa_cluster_autoscaler,
    module.kms_cluster,
    module.sg_cluster,
    module.sg_node_group,
    module.vpc,
    null_resource.aws_auth,
    null_resource.cluster_autoscaler_priority_expander,
    null_resource.flux_bootstrap,
    null_resource.flux_cluster_vars,
    null_resource.flux_ocirepository,
    null_resource.vpc_cleanup,
  ]
}
