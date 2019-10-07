#!/bin/bash
#########################################################
# This file is the startup file for the Backend service,
# it does contain also those initializations which
# are required for postgresql
#
# Author(s):
#      Juhapekka Piiroinen <juhapekka.piiroinen@csc.fi>
#
# (C) 2019 Copyright CSC - IT Center for Science Ltd.
# All Rights Reserved.
#########################################################
set -e

#########################################################
# Do the first time start up related initializations and system
# preparing which will take care that the database itself
# has the required databases and schemas.
if [[ -f /code/do-first-time-init ]]; then
    # add user creation via environment variables which should be available.
    su - postgres -c "psql -c \"create user ${PGUSER} password '${PGPASSWORD}'\""
    
    # create the database
    su - postgres -c "createdb -O ${PGUSER} ${PGDATABASE}"

    # initialize the database with qvain api schema
    su - postgres -c "psql -d ${PGDATABASE} --file=/code/qvain-api/schema/schema.sql"

    # ensure that we wont run these after the first time
    rm -f /code/do-first-time-init
fi

#########################################################
# start the service
pushd /code/qvain-api/bin
    ./qvain-backend
popd
