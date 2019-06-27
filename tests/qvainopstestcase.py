#!/usr/bin/env python3
################################################################
# This contains the base class QvainOPSTestCase with some helper
# functions for tests.
#
# This file is part of Qvain project.
#
# Author(s):
#     Juhapekka Piiroinen <juhapekka.piiroinen@csc.fi>
#
# Copyright (c) 2019 CSC - IT Center for Science Ltd.
# All Rights Reserved.
################################################################
import os
import json
import urllib3
from tauhka.testcase import TauhkaTestCase
from selenium.common.exceptions import NoSuchElementException, TimeoutException

import warnings

class QvainOPSTestCase(TauhkaTestCase):
    def __init__(self, methodName='runTest'):
        super().__init__(methodName)
        self.server = os.environ.get(
            "TEST_ADDRESS",
            "https://qvain.fairdata.fi"
        )
         
    def is_frontend_running(self):
        # This is the xpath for default error page header in nginx
        # We do not have such xpath in our frontend
        assert self.elem_is_not_found_xpath(
            "/html/body/center[1]/h1"), "Frontend is not running"

    def get_back_version(self):
        pool = urllib3.PoolManager()
        warnings.simplefilter("ignore", ResourceWarning)

        version_raw = pool.request(
            'GET', "{address}/api/version".format(
                address=self.server
            )
        ).data
        version_info = json.loads(version_raw)
        return (version_info["hash"],version_info["version"])

    def get_front_version(self):
        self.open_url(
            "{address}/config".format(
                address=self.server
            )
        )
        self.is_frontend_running()
        self.wait_until_window_title("Qvain")
        commit_hash = self.find_element_by_xpath('//*[@id="app-body"]/div/div/div/dl/dd[5]/code').text
        version = self.find_element_by_xpath('//*[@id="app-body"]/div/div/div/dl/dd[4]/code').text
        return (commit_hash, version)
        