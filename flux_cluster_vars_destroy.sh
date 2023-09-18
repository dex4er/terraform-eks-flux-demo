#!/bin/bash

asdf_tools="awscli kubectl"
. shell_common.sh

kubeconfig=$(${aws} ssm get-parameter --name ${kubeconfig_parameter} --output text --query Parameter.Value --with-decryption)

kubectl delete configmap -n flux-system cluster-vars \
  --ignore-not-found \
  --kubeconfig <(echo "${kubeconfig}") \
  --context ${cluster_context}

kubectl delete namespace flux-system \
  --ignore-not-found \
  --kubeconfig <(echo "${kubeconfig}") \
  --context ${cluster_context}
