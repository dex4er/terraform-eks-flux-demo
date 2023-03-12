## Install main Flux kustomization.

resource "null_resource" "flux_kustomization_all" {
  triggers = {
    asdf_dir             = coalesce(var.asdf_dir, ".asdf-flux_kustomization_all")
    asdf_tools           = "awscli flux2 kubectl"
    cluster_context      = local.cluster_context
    kubeconfig_parameter = aws_ssm_parameter.kubeconfig.name
    region               = var.region
  }

  provisioner "local-exec" {
    command     = "test -d ${self.triggers.asdf_dir} || git clone https://github.com/asdf-vm/asdf.git ${self.triggers.asdf_dir} --branch v0.11.2 && export ASDF_DATA_DIR=$PWD/${self.triggers.asdf_dir} && . ${self.triggers.asdf_dir}/asdf.sh && for plugin in ${self.triggers.asdf_tools}; do asdf plugin add $plugin || test $? = 2; asdf install $plugin; done"
    interpreter = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    command     = "export ASDF_DATA_DIR=$PWD/${self.triggers.asdf_dir} && . ${self.triggers.asdf_dir}/asdf.sh && kubectl apply -f flux/all.yaml --server-side --force-conflicts --kubeconfig <(aws ssm get-parameter --region ${var.region} --name ${aws_ssm_parameter.kubeconfig.name} --output text --query Parameter.Value --with-decryption) --context ${local.cluster_context} && sleep 120"
    interpreter = ["/bin/bash", "-c"]
  }

  ## Safe uninstalling of flux: 1. standard workloads; 2. controllers; 3. flux

  provisioner "local-exec" {
    when        = destroy
    command     = "test -d ${self.triggers.asdf_dir} || git clone https://github.com/asdf-vm/asdf.git ${self.triggers.asdf_dir} --branch v0.11.2 && export ASDF_DATA_DIR=$PWD/${self.triggers.asdf_dir} && . ${self.triggers.asdf_dir}/asdf.sh && for plugin in ${self.triggers.asdf_tools}; do asdf plugin add $plugin || test $? = 2; asdf install $plugin; done"
    interpreter = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "export ASDF_DATA_DIR=$PWD/${self.triggers.asdf_dir} && . ${self.triggers.asdf_dir}/asdf.sh && kubectl get kustomization all -n flux-system --no-headers --kubeconfig <(aws ssm get-parameter --region ${self.triggers.region} --name ${self.triggers.kubeconfig_parameter} --output text --query Parameter.Value --with-decryption) --context ${self.triggers.cluster_context} | while read name _rest; do flux suspend ks $name --kubeconfig <(aws ssm get-parameter --region ${self.triggers.region} --name ${self.triggers.kubeconfig_parameter} --output text --query Parameter.Value --with-decryption) --context ${self.triggers.cluster_context}; done && kubectl get kustomization -n flux-system --no-headers --kubeconfig <(aws ssm get-parameter --region ${self.triggers.region} --name ${self.triggers.kubeconfig_parameter} --output text --query Parameter.Value --with-decryption) --context ${self.triggers.cluster_context} | grep -v -P '^(all|aws-load-balancer-controller|flux-system)' | while read name _rest; do kubectl delete kustomization $name -n flux-system --ignore-not-found --kubeconfig <(aws ssm get-parameter --region ${self.triggers.region} --name ${self.triggers.kubeconfig_parameter} --output text --query Parameter.Value --with-decryption) --context ${self.triggers.cluster_context}; done && sleep 120 && kubectl get kustomization -n flux-system --no-headers --kubeconfig <(aws ssm get-parameter --region ${self.triggers.region} --name ${self.triggers.kubeconfig_parameter} --output text --query Parameter.Value --with-decryption) --context ${self.triggers.cluster_context} | grep -v -P '^(all|flux-system)' | while read name _rest; do kubectl delete kustomization $name -n flux-system --ignore-not-found --kubeconfig <(aws ssm get-parameter --region ${self.triggers.region} --name ${self.triggers.kubeconfig_parameter} --output text --query Parameter.Value --with-decryption) --context ${self.triggers.cluster_context}; done && sleep 60 && kubectl delete -f flux/all.yaml --ignore-not-found --kubeconfig <(aws ssm get-parameter --region ${self.triggers.region} --name ${self.triggers.kubeconfig_parameter} --output text --query Parameter.Value --with-decryption) --context ${self.triggers.cluster_context} && sleep 60"
    interpreter = ["/bin/bash", "-c"]
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
    null_resource.flux_bootstrap,
    null_resource.flux_cluster_vars,
    null_resource.flux_ocirepository,
    null_resource.vpc_cleanup,
  ]
}
