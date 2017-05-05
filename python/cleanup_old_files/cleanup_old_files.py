# -*- coding: utf-8 -*-
#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2017 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : cleanup_old_files.py
## Author : Denny <denny@dennyzhang.com>
## Created : <2017-05-03>
## Updated: Time-stamp: <2017-05-05 13:39:41>
## Description :
##    Remove old files in a safe and organized way
## Sample:
##    # Remove files: Check /opt/app and remove files naming "app-.*-SNAPSHOT.jar". But keep latest 2 copies
##    python cleanup_old_files.py --working_dir "/opt/app" --filename_pattern "app-*-SNAPSHOT.jar" \
##               --cleanup_type file --min_copies 3 --min_size_mb 10
##
##    # Only list delete candidates, instead of perform the actual changes
##    python cleanup_old_files.py --working_dir "/opt/app" --filename_pattern "app-*-SNAPSHOT.jar" \
##               --examine_only true
##
##    # Remove files: Only cleanup files over 200MB
##    python cleanup_old_files.py --working_dir "/opt/app" --filename_pattern "app-*-SNAPSHOT.jar" \
##               --cleanup_type file --min_size_mb 200
##
##    # Remove folders: Cleanup subdirectories, keeping latest 2 directories
##    python cleanup_old_files.py --working_dir "/opt/app" --filename_pattern "*" --cleanup_type directory
##-------------------------------------------------------------------
import os, sys
import argparse
import glob
import shutil

import logging
log_file = "/var/log/cleanup_old_files.log"

logging.basicConfig(filename=log_file, level=logging.DEBUG, format='%(asctime)s %(message)s')

def list_old_files(filename_pattern, min_copies, min_size_mb):
    l = []
    files = glob.glob(filename_pattern)
    files.sort(key=os.path.getmtime, reverse=True)
    i = 0
    for f in files:
        if os.path.isfile(f) is False:
            continue
        # skip too small files
        filesize_mb = os.stat(f).st_size/(1000*1000)
        if filesize_mb < min_size_mb:
            continue
        i = i + 1
        if i > min_copies:
            l.append(f)
    return l

def list_old_folders(filename_pattern, min_copies):
    l = []
    files = glob.glob(filename_pattern)
    files.sort(key=os.path.getmtime, reverse=True)
    i = 0
    for f in files:
        if os.path.isdir(f) is False:
            continue
        i = i + 1
        if i > min_copies:
            l.append(f)
    return l

if __name__ == '__main__':
    # get parameters from users
    parser = argparse.ArgumentParser()
    parser.add_argument('--working_dir', required=True, \
                        help="Perform cleanup under which directory", type=str)

    parser.add_argument('--examine_only', required=False, \
                        help="Only list delete candidates, instead perform the actual removal", type=str)

    parser.add_argument('--filename_pattern', required=False, default=".*", \
                        help="Filter files/directories by filename, before cleanup", type=str)
    parser.add_argument('--cleanup_type', required=False, default='file', \
                        help="Whether to perform the cleanup for files or directories", type=str)
    parser.add_argument('--min_copies', default=3, required=False, \
                        help='minimal copies to keep, before removal.', type=int)
    parser.add_argument('--min_size_mb', default='10', required=False, \
                        help='When remove files, skip files too small. It will be skipped when removing directories', type=str)
    l = parser.parse_args()

    working_dir = l.working_dir
    examine_only = l.examine_only.lower()
    cleanup_type = l.cleanup_type.lower()
    filename_pattern = l.filename_pattern
    min_copies = l.min_copies
    min_size_mb = l.min_size_mb

    logging.info("Start to run cleanup for folder: %s." % working_dir)
    if os.path.exists(working_dir) is False:
        logging.warning("Directory(%s) doesn't exists." % (working_dir))
        sys.exit(0)

    os.chdir(working_dir)
    if cleanup_type == 'file':
        l = list_old_files(filename_pattern, min_copies, min_size_mb)
    else:
        l = list_old_folders(filename_pattern, min_copies)

    if l == []:
        logging.info("No matched files/directories to be clean.")
        sys.exit(0)
    else:
        if examine_only == "true":
            logging.info("Below files/directories are selected to be removed: %s." \
                         % ",".join(l)) 
            sys.exit(0)
        else:
            # Perform the actual removal
            for f in l:
                if cleanup_type == 'file':
                    logging.info("Remove file. %s/%s." % (working_dir, f))
                else:
                    logging.info("Remove folder: %s/%s." % (working_dir, f))
                # TODO: error handling
                shutil.rmtree(f)
            logging.info("Cleanup is done.")
## File : cleanup_old_files.py ends
