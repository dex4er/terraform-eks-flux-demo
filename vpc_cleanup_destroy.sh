#!/bin/bash

asdf_tools="awscli"
. shell_common.sh

${aws} ec2 describe-security-groups \
  --query "SecurityGroups[?GroupName != 'default' && VpcId == '${vpc_id}'].GroupId" \
  --output text |
  xargs -rn1 \
    ${aws} ec2 delete-security-group --group-id

${aws} ec2 describe-network-interfaces \
  --filters \
  --query "NetworkInterfaces[?Status == 'available' && VpcId == '${vpc_id}'].NetworkInterfaceId" \
  --output text |
  xargs -rn1 \
    ${aws} ec2 delete-network-interface --network-interface-id
