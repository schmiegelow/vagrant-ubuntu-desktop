#! /usr/bin/env bash

set -o errexit -o pipefail -o nounset

loopback_device_path=/dev/loop$1
device_file=$2

umount $loopback_device_path 2>/dev/null || /bin/true
losetup -d $loopback_device_path 2>/dev/null || /bin/true
losetup $loopback_device_path $device_file
