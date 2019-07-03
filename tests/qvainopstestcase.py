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
from github import Github
from github.GithubException import RateLimitExceededException
import warnings


class QvainOPSTestCase(TauhkaTestCase):
    def __init__(self, methodName='runTest'):
        super().__init__(methodName)
        self.server = os.environ.get(
            "TEST_ADDRESS",
            "https://qvain.fairdata.fi"
        )
        self.branch = os.environ.get("GITHUB_BRANCH", "release")

    def is_frontend_running(self):
        # This is the xpath for default error page header in nginx
        # We do not have such xpath in our frontend
        assert self.elem_is_not_found_xpath(
            "/html/body/center[1]/h1"), "Frontend is not running"

    def get_git_version(self):
        try:
            username = os.environ.get("GITHUB_USERNAME", None)
            password = os.environ.get("GITHUB_PASSWORD", None)
            # You can generate token https://github.com/settings/tokens/new
            access_token = os.environ.get("GITHUB_ACCESS_TOKEN", None)
            if username and password:
                g = Github(username, password)
            elif access_token:
                g = Github(access_token)
            else:
                g = Github()
            backend_repo = g.get_repo("CSCfi/qvain-api")
            backend_hash = backend_repo.get_branch(branch=self.branch).commit.sha
            backend_tags = backend_repo.get_tags()
            backend_tag = backend_tags[0].name

            frontend_repo = g.get_repo("CSCfi/qvain-js")
            frontend_hash = frontend_repo.get_branch(branch=self.branch).commit.sha
            frontend_tags = backend_repo.get_tags()
            frontend_tag = frontend_tags[0].name

            return (frontend_hash, frontend_tag), (backend_hash, backend_tag)
        except RateLimitExceededException:
            return ("GITHUB_RATE_LIMIT", ""), ("", "")

    def get_back_version(self):
        pool = urllib3.PoolManager()
        warnings.simplefilter("ignore", ResourceWarning)

        version_raw = pool.request(
            'GET', "{address}/api/version".format(
                address=self.server
            )
        ).data
        version_info = json.loads(version_raw)
        return (version_info["hash"], version_info["version"])

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
