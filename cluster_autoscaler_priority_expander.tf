## List of allowed node groups with priorities. Higher priority is more
## important.
##
## If new node group is created with the same prefix but different number
## then autoscaler prefers newer node group. It allows to do safe upgrade of
## the nodes in the cluster.

locals {
  ## https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/expander/priority/readme.md
  cluster_autoscaler_priorities = replace(yamlencode(transpose(
    {
      for kg, vg in local.node_groups : ("^${var.name}-node-group-${kg}$") => [try(regex("-(\\d+)$", kg), ["0"])[0]] if vg.create
    }
  )), "/(?m)^\"(\\d+)\":/", "$1:")
}

resource "null_resource" "cluster_autoscaler_priority_expander" {
  triggers = {
    asdf_dir                               = coalesce(var.asdf_dir, ".asdf-cluster_autoscaler_priority_expander")
    asdf_tools                             = "awscli kubectl"
    cluster_autoscaler_priorities_checksum = sha256(local.cluster_autoscaler_priorities)
    cluster_context                        = local.cluster_context
    kubeconfig_parameter                   = aws_ssm_parameter.kubeconfig.name
    region                                 = var.region
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/asdf_install.sh"
    environment = {
      asdf_dir   = self.triggers.asdf_dir
      asdf_tools = self.triggers.asdf_tools
    }
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/cluster_autoscaler_priority_expander.sh"
    environment = {
      asdf_dir                      = self.triggers.asdf_dir
      cluster_autoscaler_priorities = local.cluster_autoscaler_priorities
      cluster_context               = self.triggers.cluster_context
      kubeconfig_parameter          = self.triggers.kubeconfig_parameter
      region                        = self.triggers.region
    }
  }

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
    command = "bash ${path.module}/cluster_autoscaler_priority_expander_destroy.sh"
    environment = {
      asdf_dir             = self.triggers.asdf_dir
      cluster_context      = self.triggers.cluster_context
      kubeconfig_parameter = self.triggers.kubeconfig_parameter
      region               = self.triggers.region
    }
  }
}
