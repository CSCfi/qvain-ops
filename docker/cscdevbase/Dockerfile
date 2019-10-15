#########################################################
# This file contains the Docker image configuration
# which will enable us to run the SSH server
# inside a container for development and testing purposes.
#
# Author(s):
#      Juhapekka Piiroinen <juhapekka.piiroinen@csc.fi>
#
# (C) 2019 Copyright CSC - IT Center for Science Ltd.
# All Rights Reserved.
#########################################################

################################################
# We base our container on centos with systemd.
FROM centos/systemd
ENV SYSTEMD_IGNORE_CHROOT=1
WORKDIR /code

################################################
# These are our arguments which we use later on
# ensure that you have defined these when building.
ARG ssh_key=""
ARG root_password="changeme"

################################################
# These are optional build time variables
ARG EXTRA_PACKAGES=""

################################################
# These are the default internal variables
ARG BASE_PACKAGES="nmap-ncat epel-release open-vm-tools openssh-server passwd rsyslog sudo cronie openssl git curl unzip which '@Development tools' htop curl vim tcl tree zile nano screen net-tools"
ARG YUM_ARGS="--setopt=tsflags=nodocs -y"
ARG GIT_USER="null-dev"
ARG GIT_EMAIL="noreply@csc.fi"

################################################
# Lets prepare the environment

# we will update packages
RUN yum update ${YUM_ARGS}

# then we will reinstall this package to get the proper
# localizations as we will need to have that finnish support
RUN yum -y -q reinstall glibc-common

# now that everything is ok, we will install those actual
# required packages which we need for running and compiling
# our software
RUN yum install ${YUM_ARGS} ${BASE_PACKAGES} ${EXTRA_PACKAGES}

################################################
# Lets clean up after installing all those files
RUN yum clean all

################################################
# Lets enable the services which we want to be there enabled
RUN systemctl enable sshd
RUN systemctl enable dbus
RUN systemctl enable rsyslog
RUN systemctl enable crond

################################################
# Configure the locale to Finnish
# as we have special characters in file names etc.
ENV LANG fi_FI.UTF-8
ENV LC_ALL fi_FI.UTF-8
RUN localedef -c -f UTF-8 -i fi_FI fi_FI.UTF-8

################################################
# Configure git client
RUN git config --global user.name ${GIT_USER}
RUN git config --global user.email ${GIT_EMAIL}

################################################
# Configure SSH server
RUN mkdir /var/run/sshd
RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''

################################################
# Configure SSH authentication
ADD ${ssh_key} /root/.ssh/authorized_keys

# Set temporary account for SSH use
RUN echo root:${root_password} | chpasswd

# Port configuration for SSH
EXPOSE 22

################################################
# What to run there inside the container
CMD /bin/echo
