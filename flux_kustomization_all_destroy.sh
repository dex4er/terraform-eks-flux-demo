#!/bin/bash

set -eu

ASDF_DATA_DIR=$(realpath "${asdf_dir}")
export ASDF_DATA_DIR
. ${ASDF_DATA_DIR}/asdf.sh

export AWS_REGION=${region}

set -x

kubeconfig=$(axws ssm get-parameter --name ${kubeconfig_parameter} --output text --query Parameter.Value --with-decryption)

kubectl apply -f flux/all.yaml \
  --server-side \
  --force-conflicts \
  --kubeconfig <(echo "${kubeconfig}") \
  --context ${cluster_context}

kubectl get kustomization all -n flux-system \
  --no-headers \
  --kubeconfig <(echo "${kubeconfig}") \
  --context ${cluster_context} |
  while read -r name _rest; do
    flux suspend ks ${name} \
      --kubeconfig <(echo "${kubeconfig}") \
      --context ${cluster_context}
  done

kubectl get kustomization -n flux-system \
  --no-headers \
  --kubeconfig <(echo "${kubeconfig}") \
  --context ${cluster_context} |
  grep -v -P "^(all|flux-system|${kustomization_to_remove_later})" |
  while read -r name _rest; do
    kubectl delete kustomization ${name} -n flux-system --ignore-not-found --kubeconfig <(echo "${kubeconfig}") --context ${cluster_context}
  done

sleep 120

kubectl get kustomization -n flux-system \
  --no-headers \
  --kubeconfig <(echo "${kubeconfig}") \
  --context ${cluster_context} |
  grep -v -P "^(all|flux-system)" |
  while read -r name _rest; do
    kubectl delete kustomization ${name} -n flux-system \
      --ignore-not-found \
      --kubeconfig <(echo "${kubeconfig}") \
      --context ${cluster_context}
  done

sleep 60

kubectl delete -f flux/all.yaml \
  --ignore-not-found \
  --kubeconfig <(echo "${kubeconfig}") \
  --context ${cluster_context}

sleep 60
