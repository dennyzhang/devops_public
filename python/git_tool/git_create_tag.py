# -*- coding: utf-8 -*-
#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2017 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : git_create_tag.py
## Author : Denny <denny@dennyzhang.com>
## Description : Create monthly git tag for all repos in your projects
## Dependency:
##        pip install GitPython
##
## Sample:
##        python git_create_tag.py --tag_name "2017-08-01" --delete_tag_already_exists \
##               --git_list_file "/tmp/git_list.txt"
##
##        Sample of git_list_file
##                   git@bitbucket.org:dennyzhang/devops.git
##                   git@bitbucket.org:dennyzhang/frontend.git
##                   git@bitbucket.org:dennyzhang/backend.git
## --
## Created : <2017-03-24>
## Updated: Time-stamp: <2017-05-20 00:12:12>
##-------------------------------------------------------------------
import os, sys
import logging
import argparse

import datetime
# Install package first: pip install GitPython
import git

log_file = "/var/log/%s.log" % (os.path.basename(__file__).rstrip('\.py'))
logging.basicConfig(filename=log_file, level=logging.DEBUG, format='%(asctime)s %(message)s')
logging.getLogger().addHandler(logging.StreamHandler())

def git_create_tag(repo_url, tag_name, delete_tag_already_exists):
    return True

def git_list_create_tag(git_list_file, tag_name, delete_tag_already_exists):
    git_list = []
    with open(git_list_file,'r') as f:
        for row in f:
            row = row.strip()
            if row == "" or row.startswith('#'):
                continue
            git_list.append(row)

    for repo_url in git_list:
        git_create_tag(repo_url, tag_name, delete_tag_already_exists)
    return True

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
##        python git_create_tag.py -tag_name "2017-08-01" --delete_tag_already_exists \
##               --git_list_file /tmp/git_list.txt"
    parser.add_argument('--tag_name', required=False, default=datetime.datetime.utcnow().strftime("%Y-%m-%d"), \
                        help="Code directories to pull. If multiple, separated by comma", type=str)
    parser.add_argument('--delete_tag_already_exists', dest='delete_tag_already_exists', \
                        action='store_true', default=False, \
                        help="Only list delete candidates, instead perform the actual removal")
    parser.add_argument('--git_list_file', required=False, default="", \
                        help="Code directories to pull. If multiple, separated by comma", type=str)
    l = parser.parse_args()
    tag_name = l.tag_name
    delete_tag_already_exists = l.delete_tag_already_exists
    git_list_file = l.git_list_file

    if git_list_create_tag(git_list_file, tag_name, delete_tag_already_exists) is True:
        logging.info("OK: Action is done successfully.")
        sys.exit(0)
    else:
        logging.error("ERROR: Action has failed.")
        sys.exit(0)
## File : git_create_tag.py ends
