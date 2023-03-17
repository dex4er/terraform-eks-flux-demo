## aws-auth is the most important ConfigMap and it is needed for nodes to be
## joined to the cluster.
##
## It is intentionaly outside Flux because accidential breaking of this file
## causes catastrophic failure of the cluster.
##
## There is a lot of troubles when Kubernetes resources are handled in the same
## configuration as AWS resources, especially on destroy or when cluster is
## recreated. To avoid problems here YAML manifest is created then applied by
## `kubectl` command, rather than by Terraform provider.

locals {
  aws_auth = yamlencode({
    apiVersion : "v1"
    kind : "ConfigMap"
    metadata : {
      name : "aws-auth"
      namespace : "kube-system"
    }
    data : {
      mapRoles : yamlencode(concat(
        [for a in concat(var.admin_role_arns, var.assume_role != null ? [var.assume_role] : []) :
          {
            rolearn : replace(a, "/(:role\\/)(.*\\/)?/", "$1")
            username : "admin:{{SessionName}}"
            groups : [
              "system:masters",
            ]
          }
        ],
        [
          {
            rolearn : replace(module.iam_role_node_group.iam_role_arn, "/(:role\\/)(.*\\/)?/", "$1")
            username : "system:node:{{EC2PrivateDNSName}}"
            groups : [
              "system:bootstrappers",
              "system:nodes",
              "system:node-proxier",
            ]
          },
        ]
      ))
      mapUsers : yamlencode(concat(
        [for a in var.admin_user_arns :
          {
            userarn  = replace(a, "/(:user\\/)(.*\\/)?/", "$1")
            username = "admin:{{SessionName}}"
          }
        ],
        [
          {
            userarn : "arn:aws:iam::${var.account_id}:root"
            username : "admin:{{SessionName}}"
          },
        ]
      ))
    }
  })
}

resource "null_resource" "aws_auth" {
  triggers = {
    aws_auth_checksum    = sha256(local.aws_auth)
    asdf_dir             = coalesce(var.asdf_dir, ".asdf-aws_auth")
    asdf_tools           = "awscli kubectl"
    cluster_context      = local.cluster_context
    kubeconfig_parameter = aws_ssm_parameter.kubeconfig.name
    region               = var.region
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/asdf_install.sh"
    environment = {
      asdf_dir   = self.triggers.asdf_dir
      asdf_tools = self.triggers.asdf_tools
    }
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/aws_auth.sh"
    environment = {
      aws_auth             = local.aws_auth
      asdf_dir             = self.triggers.asdf_dir
      cluster_context      = self.triggers.cluster_context
      kubeconfig_parameter = self.triggers.kubeconfig_parameter
      region               = self.triggers.region
    }
  }
}
