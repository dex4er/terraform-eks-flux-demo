#!/bin/bash

set -euo pipefail
shopt -s inherit_errexit 2>/dev/null || true

PREFIX=${PREFIX-}
OPERATION=${OPERATION:-=}

while true; do
  kubectl get node -L node.kubernetes.io/instance-type,eks.amazonaws.com/nodegroup,karpenter.sh/provisioner-name |
    while read -r name _status roles _age _version type nodegroup provisioner; do
      if [[ ${name} != "NAME" ]]; then
        if [[ ${OPERATION} != "-" ]] && [[ ${roles} != "<none>" ]]; then
          continue ## already labeled
        fi
        if [[ -n ${nodegroup} ]]; then
          group=${nodegroup#${PREFIX}}
          kubectl label node ${name} node-role.kubernetes.io/${group:0:39}.${type}${OPERATION}
        elif [[ -n ${provisioner} ]]; then
          group=${provisioner#${PREFIX}}
          kubectl label node ${name} node-role.kubernetes.io/${group:0:39}.${type}${OPERATION}
        fi
      fi
    done
  sleep 10
done
