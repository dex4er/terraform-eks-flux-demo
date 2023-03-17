#!/bin/bash

set -eu

ASDF_DATA_DIR=$(realpath "${asdf_dir}")
export ASDF_DATA_DIR
. ${ASDF_DATA_DIR}/asdf.sh

export AWS_REGION=${region}

set -x

aws ecr get-login-password |
  crane auth login --username AWS --password-stdin ${account_id}.dkr.ecr.${region}.amazonaws.com

flux push artifact oci://${flux_system_repository_url}:latest \
  --path=flux \
  --source=localhost \
  --revision="$(git rev-parse --short HEAD 2>/dev/null || LC_ALL=C date +%Y%m%d%H%M%S)" \
  --kubeconfig <(aws ssm get-parameter --name ${kubeconfig_parameter} --output text --query Parameter.Value --with-decryption) \
  --context ${cluster_context}
