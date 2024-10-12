#!/usr/bin/env bash

. shell_common.sh

${aws} ec2 describe-network-interfaces \
  --filters \
  --query "NetworkInterfaces[?Status == 'available' && Groups[?GroupId == '${security_group_id}']].NetworkInterfaceId" \
  --output text |
  xargs -rn1 \
    ${aws} ec2 delete-network-interface \
    --network-interface-id
