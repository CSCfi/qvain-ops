#!/bin/bash
set -e

if [[ -z ${SECRETS} ]]; then
  SECRETS=@../../secrets-demo.yaml
fi

source ../venv/bin/activate
ansible-playbook local_build.yml -i inventories/demo
ansible-playbook site_provision.yml -i inventories/demo -e ${SECRETS}
ansible-playbook install_app.yml -i inventories/demo -e ${SECRETS}
