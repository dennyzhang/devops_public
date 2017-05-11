# -*- coding: utf-8 -*-
#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2017 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : enforce_shellcheck.py
## Author : Denny <denny@dennyzhang.com>
## Description :
## --
## Created : <2017-04-02>
## Updated: Time-stamp: <2017-05-11 05:14:24>
##-------------------------------------------------------------------
import argparse
import sys
import os
import subprocess

def find_files_by_postfix(folder_check, filename_postfix):
    l = []
    for root, dirs, files in os.walk(folder_check):
        for file in files:
            if file.endswith(filename_postfix):
                l.append(os.path.join(root, file))
    return l

def ignore_files(file_list, ignore_file_list):
    if ignore_file_list is None:
        return file_list

    l = []
    for fname in file_list:
        skip = False
        for ignore_file_pattern in ignore_file_list:
            if ignore_file_pattern in fname:
                skip = True
                break
        if skip is False:
            l.append(fname)
    return l

def run_check(file_list, check_pattern):
    has_error = False
    for fname in file_list:
        check_command = check_pattern % (fname)
        print "Run check command: %s" % (check_command)
        returncode = subprocess.call(check_command, shell=True)
        if returncode != 0:
            has_error = True
            print "Error to run %s. Return code: %d" % (check_command, returncode)
    return has_error
################################################################################
#
# wget -O /tmp/enforce_shellcheck.py https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v5/python/enforce_shellcheck/enforce_shellcheck.py
# python /tmp/enforce_shellcheck.py --code_dir devops_code/devops_public
################################################################################

if __name__ == '__main__':
    # get parameters from users
    parser = argparse.ArgumentParser()
    parser.add_argument('--code_dir', required=True, \
                        help="Source code directory to be scanned", type=str)
    parser.add_argument('--check_ignore_file', required=False, \
                        help="file pattern listed in the file will be skipped for scan", type=str)

    parser.add_argument('--exclude_code_list', required=False, \
                        default="SC1090,SC1091,SC2154,SC2001,SC2002,SC2181", \
                        help="shellcheck code to be skipped", type=str)

    l = parser.parse_args()
    
    code_dir = os.path.expanduser(l.code_dir)
    if l.check_ignore_file is None:
        check_ignore_file = os.path.expanduser(l.check_ignore_file)
    else:
        check_ignore_file = None
    exclude_code_list = l.exclude_code_list

    file_list = find_files_by_postfix(code_dir, ".sh")
    if check_ignore_file is not None:
        with open(check_ignore_file) as f:
            ignore_file_list = f.readlines()
            file_list = ignore_files(file_list, ignore_file_list)

    has_error = run_check(file_list, \
                          "shellcheck -e " + exclude_code_list + " %s")
    if has_error is False:
        sys.exit(0)
    else:
        print "ERROR: %s has failed." % (os.path.basename(__file__))
        sys.exit(1)
## File : enforce_shellcheck.py ends
