#!/bin/bash

set -eu

ASDF_DATA_DIR=$(realpath "${asdf_dir}")
export ASDF_DATA_DIR
. ${asdf_dir}/asdf.sh

export AWS_REGION=${region}

set -x

aws ec2 describe-network-interfaces \
  --filters \
  --query "NetworkInterfaces[?Status == 'available' && Groups[?GroupId == '${security_group_id}']].NetworkInterfaceId" \
  --output text |
  xargs -rn1 \
    aws ec2 delete-network-interface \
    --network-interface-id
