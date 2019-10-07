#########################################################
# This file contains the Docker image configuration
# which will enable us to run the Qvain service
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
ARG BASE_PACKAGES="epel-release open-vm-tools openssh-server passwd rsyslog sudo cronie openssl git curl unzip which '@Development tools' htop curl vim tcl tree zile nano screen"
ARG YUM_ARGS="--setopt=tsflags=nodocs -y"
ARG GIT_USER="qvain-dev"
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
# Shared Qvain environment flags
################################################
RUN echo "127.0.0.1 qvain.csc.local" >> /etc/hosts


################################################
# Install Qvain API
################################################

# Install Postgresql required for Qvain API

RUN yum install ${YUM_ARGS} https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-centos96-9.6-3.noarch.rpm
RUN yum install ${YUM_ARGS} postgresql96 postgresql96-server postgresql96-contrib
RUN mkdir -p /etc/systemd/system/postgresql-9.6.service.d
RUN mkdir -p /data/pg96/QVAIN_prod

ADD postgresql/pgdata.conf /etc/systemd/system/postgresql-9.6.service.d/pgdata.conf
RUN touch /code/do-first-time-init

RUN chown -R postgres:postgres /data/pg96/
RUN su - postgres -c "/usr/pgsql-9.6/bin/pg_ctl initdb -D /data/pg96/QVAIN_prod"
ADD postgresql/pg_hba.conf /data/pg96/QVAIN_prod/pg_hba.conf

RUN systemctl enable postgresql-9.6


# Install redis
RUN yum install ${YUM_ARGS} redis
ADD redis/redis.conf /etc/redis.conf
RUN systemctl enable redis

# Others
ADD env /etc/environment

EXPOSE 8080

RUN yum install ${YUM_ARGS} golang
RUN git clone https://github.com/CSCfi/qvain-api.git
RUN cd qvain-api && make
RUN chmod +x /code/qvain-api/bin/*

# Add service file to start
RUN mkdir -p /opt/fairdata/qvain
ADD service/start-fairdata-qvain-api.sh /opt/fairdata/qvain/start-fairdata-qvain-api.sh
ADD service/fairdata-qvain-api.service /etc/systemd/system/fairdata-qvain-api.service
RUN chmod +x /opt/fairdata/qvain/start-fairdata-qvain-api.sh

# Start qvain-api on start
RUN systemctl enable fairdata-qvain-api


################################################
# Install Qvain JS
################################################
RUN yum install ${YUM_ARGS} npm
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash
RUN source ~/.bashrc && nvm install --lts
RUN git clone https://github.com/CSCfi/qvain-js.git
RUN source ~/.nvm/nvm.sh && cd qvain-js && npm install
RUN source ~/.nvm/nvm.sh && cd qvain-js && npm run dev-build
EXPOSE 8081

# Add service file to start
RUN mkdir -p /opt/fairdata/qvain
ADD service/start-fairdata-qvain-js.sh /opt/fairdata/qvain/start-fairdata-qvain-js.sh
ADD service/fairdata-qvain-js.service /etc/systemd/system/fairdata-qvain-js.service
RUN chmod +x /opt/fairdata/qvain/start-fairdata-qvain-js.sh

# Start qvain-js on start
RUN systemctl enable fairdata-qvain-js


################################################
# NGINX proxy
################################################
RUN yum install ${YUM_ARGS} nginx
RUN mkdir -p /etc/pki/selfsigned/
RUN mkdir -p /etc/nginx/qvain/
RUN mkdir -p /etc/pki/web/
RUN openssl dhparam -out /etc/pki/web/dhparam.pem 2048
RUN openssl req -x509 -nodes -subj '/C=FI/ST=Uusimaa/L=Espoo/O=CSC - Tieteen tietotekniikan keskus Oy/CN=qvain.csc.local' -days 365 -newkey rsa:2048 -keyout /etc/pki/selfsigned/cert.key -out /etc/pki/selfsigned/cert.crt
ADD nginx/includes/api.conf /etc/nginx/qvain/
ADD nginx/includes/nginx-cache-control.conf /etc/nginx/qvain/
ADD nginx/includes/nginx-robots-headers.conf /etc/nginx/qvain/
ADD nginx/includes/nginx-secure-headers.conf /etc/nginx/qvain/
ADD nginx/includes/normal-without-cache-control.conf /etc/nginx/qvain/
ADD nginx/includes/normal.conf /etc/nginx/qvain/
ADD nginx/nginx.conf /etc/nginx/

# Add service file to start
RUN systemctl enable nginx

EXPOSE 80
EXPOSE 443

################################################
# What to run there inside the container
CMD /usr/sbin/init
