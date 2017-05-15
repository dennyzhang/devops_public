# -*- coding: utf-8 -*-
#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2017 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : backup_docker_volumes.py
## Author : Denny <denny@dennyzhang.com>
## Description :
## Usage:
##            python /usr/sbin/backup_docker_volumes.py --docker_volume_list \
##               "cijenkins_volume_backup,cijenkins_volume_jobs,cijenkins_volume_workspace" \
##               --volume_dir "/var/lib/docker/volumes" --backup_dir "/data/backup/"
## --
## Created : <2017-05-12>
## Updated: Time-stamp: <2017-05-15 12:06:50>
##-------------------------------------------------------------------
import os, sys
import argparse
from datetime import datetime

import logging
log_file = "/var/log/%s.log" % (os.path.basename(__file__).rstrip('\.py'))

logging.basicConfig(filename=log_file, level=logging.DEBUG, format='%(asctime)s %(message)s')
logging.getLogger().addHandler(logging.StreamHandler())

def get_backup_fname(dst_dir, volume_name):
    return  "%s/%s-%s" % (dst_dir, volume_name, \
                          datetime.now().strftime('%Y-%m-%d-%H%M%S'))

def backup_volume(volume_dir, volume_name, backup_dir):
    backup_fname = get_backup_fname(backup_dir, volume_name)
    logging.info("Backup %s/%s to %s." % (volume_dir, volume_name, backup_fname))
    return True

if __name__ == '__main__':
    # get parameters from users
    parser = argparse.ArgumentParser()
    parser.add_argument('--docker_volume_list', required=True, default=".*", \
                        help="The list of volumes to backup. Separated by comma", type=str)
    parser.add_argument('--volume_dir', required=False, default="/var/lib/docker/volumes", \
                        help="The directory of the docker volumes", type=str)
    parser.add_argument('--backup_dir', required=False, default="/data/backup", \
                        help="Where to store the backupsets", type=str)
    l = parser.parse_args()
    volume_dir = l.volume_dir
    backup_dir = l.backup_dir
    docker_volume_list = l.docker_volume_list

    # Create backup directory, if missing
    if os.path.exists(backup_dir) is False:
        logging.warning("Warning: backup directory(%s) doesn't exist. Create it in advance." \
                        % (backup_dir))
        os.makedirs(backup_dir)

    for volume_name in docker_volume_list.split(','):
        backup_volume(volume_dir, volume_name, backup_dir)

    # TODO: List folders with depth of 2
    logging.info("List folders under %s" % (backup_dir))
    os.listdir(backup_dir)
## File : backup_docker_volumes.py ends
