#!/bin/bash
set -eux

ROOTFS=/.bottlerocket/rootfs
DISK=${ROOTFS}/dev/nvme2n1
PARTITIONS_CREATED=/.bottlerocket/bootstrap-containers/current/created
BASE_MOUNT_POINT=${ROOTFS}/var/lib/containerd

if [[ ! -f ${PARTITIONS_CREATED} ]]; then
  mkfs.ext4 -F ${DISK}
  touch ${PARTITIONS_CREATED}
fi

mkdir -p ${BASE_MOUNT_POINT}
mount ${DISK} ${BASE_MOUNT_POINT}
