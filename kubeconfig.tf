## Generates kubeconfig and stores it in AWS SSM so kubectl can use
## it without storing it locally.

locals {
  cluster_context = "arn:aws:eks:${var.region}:${var.account_id}:cluster/${var.name}"
  kubeconfig = yamlencode(
    {
      "apiVersion" : "v1",
      "clusters" : [
        {
          "cluster" : {
            "certificate-authority-data" : module.eks.cluster_certificate_authority_data,
            "server" : module.eks.cluster_endpoint
          },
          "name" : "arn:aws:eks:eu-central-1:345707776530:cluster/terraform-eks-flux-demo"
        }
      ],
      "contexts" : [
        {
          "context" : {
            "cluster" : "arn:aws:eks:eu-central-1:345707776530:cluster/terraform-eks-flux-demo",
            "user" : "arn:aws:eks:eu-central-1:345707776530:cluster/terraform-eks-flux-demo"
          },
          "name" : module.eks.cluster_arn
        }
      ],
      "current-context" : module.eks.cluster_arn,
      "kind" : "Config",
      "preferences" : {},
      "users" : [
        {
          "name" : module.eks.cluster_arn,
          "user" : {
            "exec" : {
              "apiVersion" : "client.authentication.k8s.io/v1beta1",
              "args" : concat([
                "--region",
                var.region,
                "eks",
                "get-token",
                "--cluster-name",
                module.eks.cluster_name
                ], var.assume_role != null ? [
                "--role",
                var.assume_role
              ] : []),
              "command" : "aws"
            }
          }
        }
      ]
  })
}

resource "aws_ssm_parameter" "kubeconfig" {
  name  = "${var.name}-kubeconfig"
  type  = "SecureString"
  value = local.kubeconfig

  tags = {
    Name   = "${var.name}-kubeconfig"
    Object = "aws_ssm_parameter.kubeconfig"
  }
}

output "cluster_update_kubeconfig_command" {
  value = try("aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region}", null)
}
