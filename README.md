# qvain-ops

This repository contains [Ansible](https://docs.ansible.com/ansible/) scripts to set up an instance of [Qvain](https://github.com/NatLibFi/qvain-api/).

To install the software, run:
```shell
ansible-playbook -i inventories/test site_provision.yml
```
... where `test` is one of the environments defined in [inventories](ansible/inventories/).
