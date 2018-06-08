#! /usr/bin/env bash

set -o errexit -o pipefail -o nounset

playbook_relative_path=$1

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function install_ansible {
  sudo add-apt-repository main
  sudo add-apt-repository universe
  sudo add-apt-repository restricted
  sudo add-apt-repository multiverse
  sudo apt update
  sudo apt-get install -y software-properties-common
  sudo apt-get update -y
  sudo apt-get install -y python-setuptools python-dev build-essential
  sudo apt-get install -y python-pip
  sudo pip install ansible
}

function ensure_ansible_installed {
  which_ansible_playbook_exit_code=$(which ansible-playbook &> /dev/null; echo $?)
  if [ "${which_ansible_playbook_exit_code}" -ne 0 ]; then install_ansible; fi
}

function run_playbook {
  local playbook_relative_path="${1}"

  ansible-playbook \
    --module-path="${SCRIPT_DIR}/library" \
    --inventory="localhost," \
    --connection=local \
    --become \
    --become-method=sudo \
    "${SCRIPT_DIR}/${playbook_relative_path}"
}

ensure_ansible_installed
run_playbook "$playbook_relative_path"
