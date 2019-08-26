#!/bin/bash

if [[ -z ${SECRETS} ]]; then
  SECRETS=@../../secrets-stable.yaml
fi

source ../venv/bin/activate
ansible-playbook local_build.yml -i inventories/stable
ansible-playbook site_provision.yml -i inventories/stable -e ${SECRETS}
ansible-playbook install_app.yml -i inventories/stable -e ${SECRETS}
