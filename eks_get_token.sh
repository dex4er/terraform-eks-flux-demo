#!/usr/bin/env bash

. shell_common.sh

exec ${aws} eks get-token --cluster-name "$@"
