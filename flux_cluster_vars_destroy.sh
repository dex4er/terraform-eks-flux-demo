#!/bin/bash

asdf_tools="awscli kubectl"
. shell_common.sh

kubectl delete configmap -n flux-system cluster-vars \
  --ignore-not-found \
  --kubeconfig <(aws ssm get-parameter --name ${kubeconfig_parameter} --output text --query Parameter.Value --with-decryption) \
  --context ${cluster_context}
