#!/usr/bin/env python3
################################################################
# This test can be used to get the information of the current
# version which is running on the target address.
#
# This file is part of Qvain project.
#
# Author(s):
#     Juhapekka Piiroinen <juhapekka.piiroinen@csc.fi>
#
# Copyright (c) 2019 CSC - IT Center for Science Ltd.
# All Rights Reserved.
################################################################
from qvainopstestcase import QvainOPSTestCase
import datetime

class QvainVersion(QvainOPSTestCase):
    def test_version(self):
        front_version = self.get_front_version()
        back_version = self.get_back_version()
        git_version = self.get_git_version()
        print()
        print("Server:\t{address}".format(
            address=self.server
        ))
        print("Time:\t{timestamp}".format(
            timestamp=datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        ))
        print()
        print("=== Available @ Github ===")
        print("Front:\t{tag_name}\t{commit_hash}".format(
            commit_hash=git_version[0][0],
            tag_name=git_version[0][1],
        ))
        print("Back:\t{tag_name}\t{commit_hash}".format(
            commit_hash=git_version[1][0],
            tag_name=git_version[1][1],
        ))  

        print()
        print("=== Installed @ Server ===")
        print("Front:\t{version}\t{commit_hash}".format(
            commit_hash=front_version[0],
            version=front_version[1]
        ))

        print("Back:\t{version}\t{commit_hash}".format(
            commit_hash=back_version[0],
            version=back_version[1]
        ))        
        assert front_version[1] == back_version[1], "Front and Back-end should be running the same version"
        print()


    def end_test(self):
        pass