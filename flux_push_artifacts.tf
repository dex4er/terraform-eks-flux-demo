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
    command     = ". .asdf/asdf.sh && aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${var.account_id}.dkr.ecr.${var.region}.amazonaws.com && flux push artifact oci://${local.flux_system_repository_url}:latest --path=flux --source=\"localhost\" --revision=\"$(git rev-parse --short HEAD 2>/dev/null || LC_ALL=C date +%Y%m%d%H%M%S)\" --kubeconfig <(aws ssm get-parameter --name ${aws_ssm_parameter.kubeconfig.name} --output text --query Parameter.Value --with-decryption) --context ${local.cluster_context}"
    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [
    null_resource.asdf_install,
  ]
}
