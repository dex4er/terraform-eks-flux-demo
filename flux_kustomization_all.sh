#!/bin/bash

set -eu

ASDF_DATA_DIR=$(realpath "${asdf_dir}")
export ASDF_DATA_DIR
. ${ASDF_DATA_DIR}/asdf.sh

export AWS_REGION=${region}

set -x

kubectl apply -f flux/all.yaml \
  --server-side \
  --force-conflicts \
  --kubeconfig <(aws ssm get-parameter --name ${kubeconfig_parameter} --output text --query Parameter.Value --with-decryption) \
  --context ${cluster_context}
