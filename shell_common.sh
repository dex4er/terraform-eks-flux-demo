#!/usr/bin/env bash

set -eu

if [[ -n ${profile-} ]]; then
  export AWS_PROFILE=${profile}
else
  unset AWS_PROFILE
fi
export AWS_REGION=${region}

aws="aws --region ${region}"

if [[ -n ${profile-} ]]; then
  aws="${aws} --profile ${profile}"
fi

set -x
