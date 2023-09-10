#!/bin/bash

asdf_tools="awscli envsubst kustomize kubectl"
. shell_common.sh

kustomize build flux/flux-system |
  envsubst |
  kubectl apply -f - \
    --server-side \
    --force-conflicts \
    --kubeconfig <(aws ssm get-parameter --name ${kubeconfig_parameter} --output text --query Parameter.Value --with-decryption) \
    --context ${cluster_context}
