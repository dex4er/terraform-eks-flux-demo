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
    aws_auth_checksum = sha256(local.aws_auth)
    asdf_dir          = coalesce(var.asdf_dir, "$PWD/.asdf-aws_auth")
    asdf_tools        = "awscli kubectl"
    region            = var.region
  }

  provisioner "local-exec" {
    command     = "test -d ${self.triggers.asdf_dir} || git clone https://github.com/asdf-vm/asdf.git ${self.triggers.asdf_dir} --branch v0.11.2 && export ASDF_DATA_DIR=${self.triggers.asdf_dir} && . ${self.triggers.asdf_dir}/asdf.sh && cd ${self.triggers.asdf_dir} && for plugin in ${self.triggers.asdf_tools}; do asdf plugin add $plugin || test $? = 2; asdf install $plugin; done"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      AWS_REGION = self.triggers.region
    }
  }

  provisioner "local-exec" {
    command     = "export ASDF_DATA_DIR=${self.triggers.asdf_dir} && . ${self.triggers.asdf_dir}/asdf.sh && kubectl apply -f - --server-side --kubeconfig <(aws ssm get-parameter --region ${var.region} --name ${aws_ssm_parameter.kubeconfig.name} --output text --query Parameter.Value --with-decryption) --context ${local.cluster_context} <<END\n${local.aws_auth}\nEND\n"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      AWS_REGION = self.triggers.region
    }
  }
}
