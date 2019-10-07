#!/bin/bash
#########################################################
# This file is the startup file for the Frontend service,
#
# Author(s):
#      Juhapekka Piiroinen <juhapekka.piiroinen@csc.fi>
#
# (C) 2019 Copyright CSC - IT Center for Science Ltd.
# All Rights Reserved.
#########################################################
set -e

pushd /code
    export PORT=8081
    source ~/.nvm/nvm.sh && cd qvain-js && npm run serve
popd
