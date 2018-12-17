#! /usr/bin/env bash

set -o errexit -o pipefail -o nounset

temporary_loopback_device_path=/dev/loop7
device_file=$1
device_file_owner=$2
device_file_kilobytes=$3

dd if=/dev/zero of=$device_file bs=1024 count=${device_file_kilobytes}
losetup -d $temporary_loopback_device_path 2>/dev/null || /bin/true
losetup $temporary_loopback_device_path $device_file
mkfs -t ext4 -v $temporary_loopback_device_path
temp_dir=$(mktemp -d)
mount $temporary_loopback_device_path $temp_dir
chown -R $device_file_owner:$device_file_owner $temp_dir
umount $temporary_loopback_device_path
losetup -d $temporary_loopback_device_path 2>/dev/null || /bin/true
