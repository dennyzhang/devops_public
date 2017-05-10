# -*- coding: utf-8 -*-
#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2017 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : examine_hosts_file.py
## Author : Denny <denny@dennyzhang.com>
## Created : <2017-05-03>
## Updated: Time-stamp: <2017-05-10 16:07:03>
## Description :
##    Examine /etc/hosts:
##        1. Whether expected list of ip-hostname are included in /etc/hosts
##        2. Whether it has duplicates ip-hostname binding
##        3. Whether one hostname binds to multiple ip addresses
## Sample:
##    #
##-------------------------------------------------------------------
import os, sys
import argparse
import glob
import shutil

import logging
log_file = "/var/log/%s.log" % (os.path.basename(__file__).rstrip('\.py'))

logging.basicConfig(filename=log_file, level=logging.DEBUG, format='%(asctime)s %(message)s')
logging.getLogger().addHandler(logging.StreamHandler())

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

    parser.add_argument('--examine_only', dest='examine_only', action='store_true', default=False, \
                        help="Only list delete candidates, instead perform the actual removal")

    parser.add_argument('--filename_pattern', required=False, default=".*", \
                        help="Filter files/directories by filename, before cleanup", type=str)
    parser.add_argument('--cleanup_type', required=False, default='file', \
                        help="Whether to perform the cleanup for files or directories", type=str)
    parser.add_argument('--min_copies', default=3, required=False, \
                        help='minimal copies to keep, before removal.', type=int)
    parser.add_argument('--min_size_mb', default=10, required=False, \
                        help='When remove files, skip files too small. It will be skipped when removing directories', type=int)
    l = parser.parse_args()

    working_dir = l.working_dir
    examine_only = l.examine_only
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
        if examine_only is True:
            logging.info("Below files/directories are selected to be removed: %s.\n"\
                         "Skip following removal, since --examine_only has already been given." \
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
## File : examine_hosts_file.py ends
