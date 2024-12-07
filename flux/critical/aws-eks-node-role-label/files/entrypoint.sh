#!/bin/bash

## Copyright (C) 2022-2024 Piotr Roszatycki <piotr.roszatycki@gmail.com>
## MIT License

set -euo pipefail
shopt -s inherit_errexit 2>/dev/null || true

PREFIX=${PREFIX-}
OPERATION=${OPERATION:-=}

while true; do
  kubectl get node -L node.kubernetes.io/instance-type,eks.amazonaws.com/nodegroup,eks.amazonaws.com/capacityType,karpenter.sh/nodepool,karpenter.sh/capacity-type |
    while read -r name _status roles _age _version type eks_nodegroup eks_capacity_type karpenter_nodepool karpenter_capacity_type; do
      if [[ ${name} != "NAME" ]]; then
        if [[ $OPERATION != "-" ]] && [[ ${roles} != "<none>" ]]; then
          continue ## already labeled
        fi
        if [[ -n ${eks_nodegroup} ]]; then
          group=${eks_nodegroup#$PREFIX}
          if [[ -n ${eks_capacity_type} ]]; then
            kubectl label node ${name} node-role.kubernetes.io/${group:0:30}.${type}.${eks_capacity_type,,}${OPERATION}
          fi
        elif [[ -n ${karpenter_nodepool} ]] && [[ -n ${karpenter_capacity_type} ]]; then
          group=${karpenter_nodepool#$PREFIX}
          if [[ -n ${karpenter_capacity_type} ]]; then
            kubectl label node ${name} node-role.kubernetes.io/${group:0:30}.${type}.${karpenter_capacity_type,,}${OPERATION}
          fi
        fi
      fi
    done
  sleep 10
done
