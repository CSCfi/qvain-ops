# -*- mode: ruby -*-
# vi: set ft=ruby :

# This script is to be run by saying 'vagrant up' in this folder. This script
# should be run only when creating a local development environment.

# Pre-provisioner shell script installs Ansible into the guest and continues
# to provision rest of the system in the guest. Works also on Windows.
$script = <<SCRIPT
if [ ! -f /vagrant_bootstrap_done.info ]; then
  sudo yum update
  sudo yum -y install epel-release ansible git
  cd /qvain/ansible
  ansible-playbook -i inventories/stable -e @./secrets-local.yaml site_provision.yml
  sudo touch /vagrant_bootstrap_done.info
fi
SCRIPT


required_plugins = %w( vagrant-vbguest )
required_plugins.each do |plugin|
   exec "vagrant plugin install #{plugin};vagrant #{ARGV.join(" ")}" unless Vagrant.has_plugin? plugin || ARGV[0] == 'plugin'
end

Vagrant.configure("2") do |config|
  config.vm.define "qvain_local_dev_env" do |server|
    server.vm.box = "centos/7"
    server.vm.network :private_network, ip: "10.0.0.100"

    case RUBY_PLATFORM
    when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
        # Fix Windows file rights, otherwise Ansible tries to execute files
        server.vm.synced_folder "./", "/qvain", :mount_options => ["dmode=777,fmode=777"]
    else
        # Basic VM synced folder mount
        #server.vm.synced_folder "", "/qvain", :mount_options => ["dmode=755,fmode=644"]
        server.vm.synced_folder "", "/qvain", :mount_options => ["dmode=777,fmode=777"]
    end

    server.vm.provision "shell", inline: $script

    server.vm.provider "virtualbox" do |vbox|
        vbox.name = "qvain_local_development"
        vbox.gui = false
        vbox.memory = 2046
        vbox.customize ["modifyvm", :id, "--nictype1", "virtio"]
    end
  end
end
