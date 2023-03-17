#!/bin/bash

set -eu

ASDF_DATA_DIR=$(realpath "${asdf_dir}")
export ASDF_DATA_DIR
. ${asdf_dir}/asdf.sh

export AWS_REGION=${region}

set -x

kubectl create configmap -n flux-system cluster-vars \
  --from-env-file=<(echo "${cluster_vars}") \
  --output=yaml \
  --dry-run=client |
  kubectl apply -f - \
    --server-side \
    --force-conflicts \
    --kubeconfig <(aws ssm get-parameter --name ${kubeconfig_parameter} --output text --query Parameter.Value --with-decryption) \
    --context ${cluster_context}