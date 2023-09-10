#!/bin/bash

asdf_tools="awscli envsubst kubectl kustomize"
. shell_common.sh

kubectl apply -k https://github.com/fluxcd/flux2/manifests/install?ref=v2.1.0 \
  --server-side \
  --force-conflicts \
  --kubeconfig <(aws ssm get-parameter --name ${kubeconfig_parameter} --output text --query Parameter.Value --with-decryption) \
  --context ${cluster_context}

cat flux/flux-system/gitrepository.yaml flux/flux-system.yaml |
  envsubst |
  kubectl apply -f - \
    --server-side \
    --force-conflicts \
    --kubeconfig <(aws ssm get-parameter --name ${kubeconfig_parameter} --output text --query Parameter.Value --with-decryption) \
    --context ${cluster_context}
