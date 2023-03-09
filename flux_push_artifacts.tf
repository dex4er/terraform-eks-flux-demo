## Push ./flux directory to ECR repository

data "archive_file" "flux" {
  type        = "zip"
  source_dir  = "flux"
  output_path = ".flux.zip"
}

resource "null_resource" "flux_push_artifact" {
  triggers = {
    flux_directory_checksum = data.archive_file.flux.output_base64sha256
  }

  provisioner "local-exec" {
    command = "aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${var.account_id}.dkr.ecr.${var.region}.amazonaws.com && flux push artifact oci://${local.flux_system_repository_url}:latest --path=flux --source=\"localhost\" --revision=\"$(git rev-parse --short HEAD 2>/dev/null || LC_ALL=C date +%Y%m%d%H%M%S)\" --kubeconfig .kube/config --context ${local.cluster_context}"
  }

  depends_on = [
    local_file.flux_cluster_autoscaler_priority_expander,
    local_file.flux_cluster_vars,
    local_file.flux_ocirepository,
    null_resource.aws_eks_update-kubeconfig_terraform,
  ]
}
