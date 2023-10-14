#!/bin/bash

asdf_tools="awscli envsubst kubectl kustomize"
. shell_common.sh

kubeconfig=$(${aws} ssm get-parameter --name ${kubeconfig_parameter} --output text --query Parameter.Value --with-decryption)

kubectl apply -k https://github.com/fluxcd/flux2/manifests/crds?ref=v2.1.0 \
  --server-side \
  --force-conflicts \
  --kubeconfig <(echo "${kubeconfig}") \
  --context ${cluster_context}

kubectl create secret generic -n flux-system flux-system \
  --from-literal=password="${flux_git_repository_password-}" \
  --from-literal=username="${flux_git_repository_username-}" \
  --output=yaml \
  --dry-run=client |
  kubectl apply -f - \
    --server-side \
    --force-conflicts \
    --kubeconfig <(echo "${kubeconfig}") \
    --context ${cluster_context}

kustomize build flux/flux-system |
  envsubst |
  kubectl apply -f - \
    --server-side \
    --force-conflicts \
    --kubeconfig <(echo "${kubeconfig}") \
    --context ${cluster_context}

cat flux/flux-system.yaml |
  envsubst |
  kubectl apply -f - \
    --server-side \
    --force-conflicts \
    --kubeconfig <(echo "${kubeconfig}") \
    --context ${cluster_context}

kubectl get gitrepository flux-system -n flux-system \
  --no-headers \
  --kubeconfig <(echo "${kubeconfig}") \
  --context ${cluster_context} |
  while read -r name _rest; do
    flux resume source git ${name} \
      --kubeconfig <(echo "${kubeconfig}") \
      --context ${cluster_context}
  done

kubectl get kustomization flux-system -n flux-system \
  --no-headers \
  --kubeconfig <(echo "${kubeconfig}") \
  --context ${cluster_context} |
  while read -r name _rest; do
    flux resume ks ${name} \
      --kubeconfig <(echo "${kubeconfig}") \
      --context ${cluster_context}
  done
