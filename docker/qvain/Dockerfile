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
FROM cscdevbase:1
WORKDIR /code

ARG qvain_password="changeme"
ARG YUM_ARGS="--setopt=tsflags=nodocs -y"

# Create user account for qvain
RUN adduser qvain
RUN echo qvain:${qvain_password} | chpasswd
RUN chown qvain:qvain /code

################################################
# Install Qvain API
################################################

# Others
ADD env /etc/environment
RUN touch /code/do-first-time-init

EXPOSE 8080

RUN yum install ${YUM_ARGS} golang postgresql

USER qvain
RUN git clone https://github.com/CSCfi/qvain-api.git
RUN cd qvain-api && make
RUN chmod +x /code/qvain-api/bin/*

USER root

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

EXPOSE 8081

USER qvain
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash
RUN source ~/.bashrc && nvm install --lts
RUN git clone https://github.com/CSCfi/qvain-js.git
RUN source ~/.nvm/nvm.sh && cd qvain-js && npm install
RUN source ~/.nvm/nvm.sh && cd qvain-js && npm run dev-build
USER root

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
