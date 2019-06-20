# local_build role

This role clones the qvain-api and qvain-js repositories and builds them locally on the machine running Ansible. The current user is used and no sudo access is needed.

The qvain-api and qvain-js directories will be placed under the parent of the playbook directory, i.e. qvain-ops. Git checkout is used with the force option, so any local uncommitted changes to will be lost.

For building the front-end, the role downloads nvm and uses it to install the latest Node LTS version for the current user.

## Requirements

You need to have git, ansible and go installed.

For example, on Centos 7 you can install the required packages with:
```
sudo yum install git ansible epel-release
sudo yum install golang
```

## Usage

The role is meant to be run using the local_build.yml playbook and an inventory corresponding to the desired build target. To build Qvain for production, run the following command in the qvain-ops/ansible directory:
```
ansible-playbook -i inventories/production local_build.yml
```

The built distribution directories will be symlinked into qvain-ops/releases/production.
