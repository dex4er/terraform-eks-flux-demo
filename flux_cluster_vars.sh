#!/bin/bash

asdf_tools="awscli kubectl"
. shell_common.sh

kubectl create configmap -n flux-system cluster-vars \
  --from-env-file=<(echo "${cluster_vars}") \
  --output=yaml \
  --dry-run=client |
  kubectl apply -f - \
    --server-side \
    --force-conflicts \
    --kubeconfig <(${aws} ssm get-parameter --name ${kubeconfig_parameter} --output text --query Parameter.Value --with-decryption) \
    --context ${cluster_context}
