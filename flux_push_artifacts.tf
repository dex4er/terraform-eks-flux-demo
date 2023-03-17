## Push ./flux directory to ECR repository

data "archive_file" "flux" {
  type        = "zip"
  source_dir  = "flux"
  output_path = ".flux.zip"
}

resource "null_resource" "flux_push_artifact" {
  triggers = {
    asdf_dir                = coalesce(var.asdf_dir, "$PWD/.asdf-flux_push_artifact")
    asdf_tools              = "awscli flux2 go-containerregistry"
    flux_directory_checksum = data.archive_file.flux.output_base64sha256
    region                  = var.region
  }

  provisioner "local-exec" {
    command     = "test -d ${self.triggers.asdf_dir} || git clone https://github.com/asdf-vm/asdf.git ${self.triggers.asdf_dir} --branch v0.11.2 && export ASDF_DATA_DIR=${self.triggers.asdf_dir} && . ${self.triggers.asdf_dir}/asdf.sh && cd ${self.triggers.asdf_dir} && for plugin in ${self.triggers.asdf_tools}; do asdf plugin add $plugin || test $? = 2; asdf install $plugin; done"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      AWS_REGION = self.triggers.region
    }
  }

  provisioner "local-exec" {
    command     = "export ASDF_DATA_DIR=${self.triggers.asdf_dir} && . ${self.triggers.asdf_dir}/asdf.sh && aws ecr get-login-password --region ${var.region} | crane auth login --username AWS --password-stdin ${var.account_id}.dkr.ecr.${var.region}.amazonaws.com && flux push artifact oci://${local.flux_system_repository_url}:latest --path=flux --source=\"localhost\" --revision=\"$(git rev-parse --short HEAD 2>/dev/null || LC_ALL=C date +%Y%m%d%H%M%S)\" --kubeconfig <(aws ssm get-parameter --region ${var.region} --name ${aws_ssm_parameter.kubeconfig.name} --output text --query Parameter.Value --with-decryption) --context ${local.cluster_context}"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      AWS_REGION = self.triggers.region
    }
  }
}
