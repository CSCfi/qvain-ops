#!/bin/bash
set -e

if [[ -z ${SECRETS} ]]; then
  SECRETS=@../../secrets-test.yaml
fi

source ../venv/bin/activate
ansible-playbook local_build.yml -i inventories/test
ansible-playbook site_provision.yml -i inventories/test -e ${SECRETS}
ansible-playbook install_app.yml -i inventories/test -e ${SECRETS}
