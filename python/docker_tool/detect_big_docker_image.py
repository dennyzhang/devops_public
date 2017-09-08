#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2017 DennyZhang.com
## Licensed under MIT
##   https://www.dennyzhang.com/wp-content/mit_license.txt
##
## File : detect_big_docker_image.py
## Author : Denny <contact@dennyzhang.com>
## Description : Make sure all docker images you build in your docker host machine are small enough
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
                print("Skip check for %s" % (item))
                break
        if should_skip is False:
            ret_list.append(item)
    return ret_list

def list_all_docker_tag(client):
    tag_list = []
    for image in client.images.list():
        for tag in image.tags:
            tag_list.append(tag)
    return tag_list

def get_image_size_by_tag_mb(tag_name, client):
    # raise exception, if image not found
    image = client.images.get(tag_name)
    size_mb = float(image.attrs['Size'])/(1024*1024)
    return round(size_mb, 2)

def list_image_list(tag_list, client):
    print("Show image status:")
    print("{0:40} {1}".format("IMAGE_TAG", "SIZE"))
    for tag_name in tag_list:
        size_mb = get_image_size_by_tag_mb(tag_name, client)
        print("{0:40} {1}MB".format(tag_name, size_mb))

def examine_docker_images(checklist_file, whitelist_file, client):
    problematic_list = []

    tag_list = list_all_docker_tag(client)
    tag_list = skip_items_by_whitelist(tag_list, whitelist_file)

    check_list = []
    with open(checklist_file,'r') as f:
        for row in f:
            row = row.strip()
            if row == "" or row.startswith('#'):
                continue
            check_list.append(row)
    for tag_name in tag_list:
        has_matched = False
        for check_rule in check_list:
            l = check_rule.split(":")
            tag_name_pattern = ".".join(l[0:-1])
            max_size_mb = float(l[-1])
            if re.search(tag_name_pattern, tag_name):
                has_matched = True
                # print("tag_name: %s, check_rule: %s" % (tag_name, check_rule))
                image_size_mb = get_image_size_by_tag_mb(tag_name, client)
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

    # https://docker-py.readthedocs.io/en/stable/client.html
    client = docker.from_env()
    problematic_list = examine_docker_images(checklist_file, whitelist_file, client)
    if len(problematic_list) == 0:
        print("OK: all docker images are as small as you wish.")
    else:
        print("ERROR: below docker images are bigger than you wish.")
        list_image_list(problematic_list, client)
        sys.exit(1)
## File : detect_big_docker_image.py ends
