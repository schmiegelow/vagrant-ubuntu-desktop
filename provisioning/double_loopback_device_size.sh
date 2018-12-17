#!/usr/bin/env bash

set -o errexit -o pipefail -o nounset

loopback_device_path=/dev/loop$1
device_file=$2

block_size=$(sudo dumpe2fs "${loopback_device_path}" 2>/dev/null | grep "^Block size:" | awk '{ print $3 }')
block_count=$(sudo dumpe2fs "${loopback_device_path}" 2>/dev/null | grep "^Block count:" | awk '{ print $3 }')

umount "${loopback_device_path}"
dd if=/dev/zero bs=${block_size} of="${device_file}" conv=notrunc oflag=append count=${block_count} >/dev/null 2>&1
losetup -c "${loopback_device_path}"
e2fsck -f -a "${loopback_device_path}" >/dev/null
resize2fs "${loopback_device_path}" >/dev/null 2>&1
mount "${loopback_device_path}"