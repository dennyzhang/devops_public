# -*- coding: utf-8 -*-
#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2017 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : detect_big_docker_image.py
## Author : Denny <denny@dennyzhang.com>
## Description : Make sure all docker images you build is small enough
## Usage:
##    python detect_big_docker_image.py --checklist_file "/tmp/check_list.txt" --whitelist_file "/tmp/whitelist.txt"
##
##    Example of /tmp/check_list.txt
##              # mysql should not exceed 450 MB
##              mysql.*:450
##              # all images should not exceed 300 MB
##              .*:300
##
##    Example of /tmp/whitelist_file:
##              denny/jenkins.*
##              .*<none>.*
##              .*test.*
##              .*_JENKINS_TEST.*
##
## --
## Created : <2017-05-12>
## Updated: Time-stamp: <2017-05-19 10:52:18>
##-------------------------------------------------------------------
import os, sys
import argparse
import docker
import re

import logging
log_file = "/var/log/%s.log" % (os.path.basename(__file__).rstrip('\.py'))

logging.basicConfig(filename=log_file, level=logging.DEBUG, format='%(asctime)s %(message)s')
logging.getLogger().addHandler(logging.StreamHandler())

def skip_items_by_whitelist(item_list, whitelist_file):
    ret_list = []
    skip_list = []
    # load skip rules from config file
    with open(whitelist_file,'r') as f:
        for row in f:
            row = row.strip()
            if row == "" or row.startswith('#'):
                continue
            skip_list.append(row)
    for item in item_list:
        should_skip = False
        for skip_rule in skip_list:
            if re.search(skip_rule, item):
                should_skip = True
                logging.info("Skip check for %s" % (item))
                break
        if should_skip is False:
            ret_list.append(item)
    return ret_list

def list_all_docker_tag(client = None):
    # https://docker-py.readthedocs.io/en/stable/client.html
    if client is None:
        client = docker.from_env()
    tag_list = []
    for image in client.images.list():
        for tag in image.tags:
            tag_list.append(tag)
    return tag_list

def get_image_size_by_tag_mb(tag_name, cli_client = None):
    # Use Python Low-level API: https://docker-py.readthedocs.io/en/stable/api.html
    if cli_client is None:
        cli_client = docker.APIClient(base_url='unix://var/run/docker.sock')
    # raise exception, if image not found
    response_list = cli_client.inspect_image(tag_name)
    size_mb = float(response_list['Size'])/(1024*1024)
    return round(size_mb, 2)

def list_image_list(tag_list, cli_client = None):
    if cli_client is None:
        cli_client = docker.APIClient(base_url='unix://var/run/docker.sock')
    logging.info("Show image status.\n%s\t%s\n" % ("IMAGE TAG", "SIZE"))
    for tag_name in tag_list:
        size_mb = get_image_size_by_tag_mb(tag_name)
        logging.info("%s\t%sMB" % (tag_name, size_mb))

def examine_docker_images(checklist_file, whitelist_file):
    problematic_list = []

    cli_client = docker.APIClient(base_url='unix://var/run/docker.sock')
    client = docker.from_env()
    tag_list = list_all_docker_tag(client)
    tag_list = skip_items_by_whitelist(tag_list, whitelist_file)

    check_list = []
    with open(checklist_file,'r') as f:
        for row in f:
            row = row.strip()
            if row == "" or row.startswith('#'):
                continue
            check_list.append(row)
    # print check_list
    for tag_name in tag_list:
        has_matched = False
        for check_rule in check_list:
            l = check_rule.split(":")
            tag_name_pattern = l[0]
            max_size_mb = float(l[1])
            if re.search(tag_name_pattern, tag_name):
                has_matched = True
                # print "tag_name: %s, check_rule: %s" % (tag_name, check_rule)
                image_size_mb = get_image_size_by_tag_mb(tag_name, cli_client)
                if image_size_mb > max_size_mb:
                    problematic_list.append(tag_name)
                break
    return problematic_list
################################################################################

if __name__ == '__main__':
    # get parameters from users
    parser = argparse.ArgumentParser()
    parser.add_argument('--checklist_file', required=True, \
                        help="The list of volumes to backup. Separated by comma", type=str)
    parser.add_argument('--whitelist_file', required=True, \
                        help="The list of volumes to backup. Separated by comma", type=str)

    l = parser.parse_args()
    checklist_file = l.checklist_file
    whitelist_file = l.whitelist_file

    problematic_list = examine_docker_images(checklist_file, whitelist_file)
    if len(problematic_list) == 0:
        logging.info("OK: all docker images are as small as you wish.")
    else:
        logging.error("ERROR: below docker images are bigger than you wish.")
        list_image_list(problematic_list)
        sys.exit(1)
## File : detect_big_docker_image.py ends
