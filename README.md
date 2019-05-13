# qvain-ops

This repository contains [Ansible](https://docs.ansible.com/ansible/) scripts to set up an instance of [Qvain](https://github.com/CSCfi/qvain-api/).

## setting up a development environment

To install a local development environment using vagrant, clone the repository, and inside the repository, run:

```shell
vagrant up
```

After, you should modify your host /etc/hosts file to include:

```
10.0.0.100 qvain.csc.local
```

After that, you should be able to direct your web browser to https://qvain.csc.local to access Qvain. For login, credentials for a test instance of a centralized authentication component are additionally required (unless developing the frontend or the backand in standalone mode).

SSH inside the new vm:

```shell
vagrant ssh
```

To re-execute ansible tasks:

```shell
cd /qvain/ansible
sudo -i
ansible-playbook site_provision.yml
```

### frontend development

The frontend repository `qvain-js` is cloned to `qvain-ops/qvain-js`. On your host machine, you can run `npm run build-watch` or similar in `qvain-js` and the changes in the `qvain-ops/qvain-js/dist/` directory will reflect on the development vm.

Frontend can also be developed independently of a backend, by starting the npm development server, and directing the web browser to it.

### backend development

The backend repository `qvain-api` is cloned to `qvain-ops/qvain-api`. Changes made to `qvain-api` on you host machine are reflected on the development vm.

## setting up remote test environments

To execute ansible tasks for other environments than local development, in ansible/, execute:

ansible-playbook -i inventories/test site_provision.yml --private-key=path/to/private/key.pem -e @./secrets/secrets-test.yaml

... where `inventories/test` and `secrets-test.yaml` is one of the environments defined in [inventories](ansible/inventories/).
