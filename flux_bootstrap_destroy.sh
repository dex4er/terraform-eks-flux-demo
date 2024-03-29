#!/bin/bash

asdf_tools="awscli flux2 kubectl"
kustomization_to_remove_later="flux-system|infrastructure"
. shell_common.sh

kubeconfig=$(${aws} ssm get-parameter --name ${kubeconfig_parameter} --output text --query Parameter.Value --with-decryption)

kubectl get gitrepository flux-system -n flux-system \
  --no-headers \
  --kubeconfig <(echo "${kubeconfig}") \
  --context ${cluster_context} |
  while read -r name _rest; do
    flux suspend source git ${name} \
      --kubeconfig <(echo "${kubeconfig}") \
      --context ${cluster_context}
  done

kubectl get kustomization flux-system -n flux-system \
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
  grep -v -E "^(${kustomization_to_remove_later})" |
  while read -r name _rest; do
    kubectl delete kustomization ${name} -n flux-system --ignore-not-found --kubeconfig <(echo "${kubeconfig}") --context ${cluster_context}
  done

sleep 180

kubectl get kustomization -n flux-system \
  --no-headers \
  --kubeconfig <(echo "${kubeconfig}") \
  --context ${cluster_context} |
  grep -v -E "^flux-system" |
  while read -r name _rest; do
    kubectl delete kustomization ${name} -n flux-system \
      --ignore-not-found \
      --kubeconfig <(echo "${kubeconfig}") \
      --context ${cluster_context}
  done

sleep 60

kubectl delete secret -n flux-system flux-system \
  --ignore-not-found \
  --kubeconfig <(echo "${kubeconfig}") \
  --context ${cluster_context}

flux uninstall --keep-namespace=true --silent \
  --kubeconfig <(echo "${kubeconfig}") \
  --context ${cluster_context}
