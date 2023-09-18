#!/bin/bash

asdf_tools="awscli kubectl"
. shell_common.sh

kubeconfig=$(${aws} ssm get-parameter --name ${kubeconfig_parameter} --output text --query Parameter.Value --with-decryption)

kubectl create ns flux-system \
  --output=yaml \
  --dry-run=client |
  kubectl apply -f - \
    --server-side \
    --force-conflicts \
    --kubeconfig <(echo "${kubeconfig}") \
    --context ${cluster_context}

kubectl create configmap -n flux-system cluster-vars \
  --from-env-file=<(echo "${cluster_vars}") \
  --output=yaml \
  --dry-run=client |
  kubectl apply -f - \
    --server-side \
    --force-conflicts \
    --kubeconfig <(echo "${kubeconfig}") \
    --context ${cluster_context}
