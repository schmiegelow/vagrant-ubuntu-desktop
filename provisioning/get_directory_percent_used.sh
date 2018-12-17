#!/usr/bin/env bash

set -o errexit -o pipefail -o nounset

directory=$1

df --output=pcent "${directory}" | tail -n1 | cut -d ' ' -f2 | tr -d '%'