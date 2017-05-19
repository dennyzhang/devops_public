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
##            python /usr/sbin/detect_big_docker_image.py \
##                   --check_list_file "/tmp/check_list.txt"
##                   --whitelist_file "/tmp/whitelist.txt"
## --
## Created : <2017-05-12>
## Updated: Time-stamp: <2017-05-19 10:35:54>
##-------------------------------------------------------------------
import os, sys
import argparse
import docker

import logging
log_file = "/var/log/%s.log" % (os.path.basename(__file__).rstrip('\.py'))

logging.basicConfig(filename=log_file, level=logging.DEBUG, format='%(asctime)s %(message)s')
logging.getLogger().addHandler(logging.StreamHandler())

def skip_items_by_whitelist(item_list, whitelist_file):
    import re
    ret_list = []
    return ret_list

def list_all_docker_tag(client):
    tag_list = []
    for image in client.images.list():
        for tag in image.tags:
            tag_list.append(tag)
    return tag_list

################################################################################

if __name__ == '__main__':
    # get parameters from users
    parser = argparse.ArgumentParser()
    parser.add_argument('--check_list_file', required=True, \
                        help="The list of volumes to backup. Separated by comma", type=str)
    parser.add_argument('--whitelist_file', required=True, \
                        help="The list of volumes to backup. Separated by comma", type=str)

    l = parser.parse_args()
    volume_dir = l.volume_dir
    backup_dir = l.backup_dir
    docker_volume_list = l.docker_volume_list
## File : detect_big_docker_image.py ends
