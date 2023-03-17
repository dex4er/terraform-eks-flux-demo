#!/bin/bash

set -eu

ASDF_DATA_DIR=$(realpath "${asdf_dir}")
export ASDF_DATA_DIR
. ${asdf_dir}/asdf.sh

export AWS_REGION=${region}

set -x

flux reconcile source oci flux-system \
  --kubeconfig <(aws ssm get-parameter --name ${kubeconfig_parameter} --output text --query Parameter.Value --with-decryption) \
  --context ${cluster_context}

flux reconcile ks all \
  --kubeconfig <(aws ssm get-parameter --name ${kubeconfig_parameter} --output text --query Parameter.Value --with-decryption) \
  --context ${cluster_context}
