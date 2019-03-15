#!/bin/sh -e
#
# -wvh- install and run ansible
#

BASEDIR=$(readlink -f $(dirname $0)/../)

if [ ! -f .bootstrap_ansible_yum.done ]; then
	sudo yum update
	sudo yum -y install epel-release ansible git
	touch .bootstrap_ansible_yum.done
else
	echo $0: "bootstrap ansible yum: done"
fi

if [ ! -f .bootstrap_ansible_provision.done ]; then
	cd ${BASEDIR}/ansible
	#ansible-playbook -i site_provision.yml
	ansible all -i inventories/builder -e @../scripts/secrets-production.yaml -m debug -a "msg={{hostvars}}"
	ansible-playbook -i inventories/builder -e @../scripts/secrets-production.yaml provision_appserver.yml
	cd
	touch .bootstrap_ansible_provision.done
else
	echo $0: "bootstrap ansible provision: done"
fi
