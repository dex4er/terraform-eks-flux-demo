#!/bin/bash

asdf_tools="awscli envsubst kubectl kustomize"
. shell_common.sh

kubeconfig=$(${aws} ssm get-parameter --name ${kubeconfig_parameter} --output text --query Parameter.Value --with-decryption)

kubectl apply -k https://github.com/fluxcd/flux2/manifests/install?ref=v2.1.0 \
  --server-side \
  --force-conflicts \
  --kubeconfig <(echo "${kubeconfig}") \
  --context ${cluster_context}

for f in flux/flux-system/gitrepository.yaml flux/flux-system.yaml; do
  echo "---"
  cat ${f} |
    envsubst
done |
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
