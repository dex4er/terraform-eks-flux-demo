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

resource "local_file" "aws_auth" {
  content = yamlencode({
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
  filename             = "aws_auth.yaml"
  directory_permission = "0755"
  file_permission      = "0644"
}

resource "null_resource" "apply_aws_auth" {
  triggers = {
    content_checksum = sha256(local_file.aws_auth.content)
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${local_file.aws_auth.filename} --server-side --kubeconfig .kube/config --context ${local.cluster_context}"
  }

  depends_on = [
    null_resource.aws_eks_update-kubeconfig_terraform,
  ]
}
