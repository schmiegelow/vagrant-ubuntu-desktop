#! /usr/bin/env bash

set -o errexit -o pipefail -o nounset

loopback_device_path=/dev/loop$1
device_file=$2

losetup "${loopback_device_path}" 2>/dev/null | grep --quiet '('"${device_file}"')'