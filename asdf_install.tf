## Install asdf and tools required by other local-exec

resource "null_resource" "asdf_install" {
  triggers = {
    account_id                             = var.account_id
    aws_auth_checksum                      = sha256(local.aws_auth)
    azs                                    = join(",", [for i, v in var.azs : "${i}=${v}"])
    cluster_autoscaler_priorities_checksum = sha256(local.cluster_autoscaler_priorities)
    cluster_context                        = local.cluster_context
    flux_directory_checksum                = data.archive_file.flux.output_base64sha256
    flux_system_repository_url             = local.flux_system_repository_url
    kubeconfig_parameter                   = aws_ssm_parameter.kubeconfig.name
    name                                   = var.name
    region                                 = var.region
    vpc_id                                 = local.vpc_id
  }

  provisioner "local-exec" {
    command     = "rm -rf .asdf && git clone https://github.com/asdf-vm/asdf.git .asdf --branch v0.11.2 && . .asdf/asdf.sh && while read plugin version; do asdf plugin add $plugin || test $? = 2; done < .tool-versions; asdf install"
    interpreter = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "rm -rf .asdf"
    interpreter = ["/bin/bash", "-c"]
  }
}
