#!/usr/bin/env bash

kustomization_to_remove_later="flux-system|critical"
. shell_common.sh

kubeconfig=$(${aws} ssm get-parameter --name ${kubeconfig_parameter} --output text --query Parameter.Value --with-decryption)

kubectl get gitrepository flux-system -n flux-system \
  --no-headers \
  --kubeconfig <(echo "${kubeconfig}") \
  --context ${cluster_context} |
  while read -r name _rest; do
    kubectl patch gitrepository ${name} -n flux-system \
      --kubeconfig <(echo "${kubeconfig}") \
      --context ${cluster_context} \
      --type='merge' \
      --patch '{"spec":{"suspend":true}}'
  done

kubectl get kustomization flux-system -n flux-system \
  --no-headers \
  --kubeconfig <(echo "${kubeconfig}") \
  --context ${cluster_context} |
  while read -r name _rest; do
    kubectl patch kustomization ${name} -n flux-system \
      --kubeconfig <(echo "${kubeconfig}") \
      --context ${cluster_context} \
      --type='merge' \
      --patch '{"spec":{"suspend":true}}'
  done

kubectl get kustomization -n flux-system \
  --no-headers \
  --kubeconfig <(echo "${kubeconfig}") \
  --context ${cluster_context} |
  grep -v -E "^(${kustomization_to_remove_later})" |
  while read -r name _rest; do
    kubectl delete kustomization ${name} -n flux-system \
      --ignore-not-found \
      --kubeconfig <(echo "${kubeconfig}") \
      --context ${cluster_context}
  done

kubectl get services -A \
  --no-headers \
  --kubeconfig <(echo "${kubeconfig}") \
  --context ${cluster_context} |
  grep -v -E "^(${kustomization_to_remove_later})" |
  while read -r namespace name type _rest; do
    if [[ ${type} == "LoadBalancer" ]]; then
      kubectl delete service ${name} -n ${namespace} \
        --ignore-not-found \
        --kubeconfig <(echo "${kubeconfig}") \
        --context ${cluster_context}
    fi
  done

kubectl delete targetgroupbindings -A \
  --all \
  --ignore-not-found

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

kubectl patch namespace flux-system \
  --kubeconfig <(echo "${kubeconfig}") \
  --context ${cluster_context} \
  --type='merge' \
  --patch '{"metadata":{"finalizers":null}}'
