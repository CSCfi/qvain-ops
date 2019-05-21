#!/bin/bash
############################################################
# This script allows easy startup of the frontend instance
# for developer use.
#
# This file is part of Qvain project.
#
# Author(s):
#     Juhapekka Piiroinen <juhapekka.piiroinen@csc.fi>
#
# Copyright 2019 CSC - IT Center for Science Ltd.
# Copyright 2019 The National Library Of Finland
# All Rights Reserved.
############################################################
screen -r qvain-js
if [[ $? -ne 0 ]]; then
  ./client-start.sh
  ./client-console.sh
fi
