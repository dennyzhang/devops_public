#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2017 DennyZhang.com
## Licensed under MIT
##   https://www.dennyzhang.com/wp-content/mit_license.txt
##
## File : enforce_shellcheck.py
## Author : Denny <contact@dennyzhang.com>
## Description :
##
## More reading: https://www.dennyzhang.com/shellcheck
##
## --
## Created : <2017-04-02>
## Updated: Time-stamp: <2017-09-07 21:36:06>
##-------------------------------------------------------------------
import argparse
import sys
import os
import subprocess
import re

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
            ignore_file_pattern = ignore_file_pattern.strip().strip("\n")
            if ignore_file_pattern == "":
                continue
            if re.search(ignore_file_pattern, fname) is not None :
                skip = True
                break
        if skip is False:
            l.append(fname)
    return l

def run_check(file_list, check_pattern):
    has_error = False
    for fname in file_list:
        check_command = check_pattern % (fname)
        print("Run check command: %s" % (check_command))
        returncode = subprocess.call(check_command, shell=True)
        if returncode != 0:
            has_error = True
            print("Error to run %s. Return code: %d" % (check_command, returncode))
    return has_error
################################################################################
#
# wget -O /tmp/enforce_shellcheck.py https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v6/python/enforce_shellcheck/enforce_shellcheck.py
# python /tmp/enforce_shellcheck.py --code_dir devops_code/devops_public
################################################################################

if __name__ == '__main__':
    # get parameters from users
    parser = argparse.ArgumentParser()
    parser.add_argument('--code_dir', required=False, default=".", \
                        help="Source code directory to be scanned", type=str)
    parser.add_argument('--check_ignore_file', required=False, default="", \
                        help="file pattern listed in the file will be skipped for scan", type=str)
    parser.add_argument('--exclude_code_list', required=False, \
                        default="SC1090,SC1091,SC2154,SC2001,SC2002,SC2181", \
                        help="shellcheck code to be skipped", type=str)

    l = parser.parse_args()

    code_dir = os.path.expanduser(l.code_dir)
    check_ignore_file = l.check_ignore_file

    if len(os.listdir(code_dir)) == 0:
        print("ERROR: code directory(%s) is empty." % (code_dir))
        sys.exit(1)

    if check_ignore_file != "":
        check_ignore_file = os.path.expanduser(l.check_ignore_file)

    exclude_code_list = l.exclude_code_list

    print("Run shellcheck for *.sh under %s" % (code_dir))
    file_list = find_files_by_postfix(code_dir, ".sh")
    if check_ignore_file != "":
        with open(check_ignore_file) as f:
            ignore_file_list = f.readlines()
            file_list = ignore_files(file_list, ignore_file_list)

    has_error = run_check(file_list, \
                          "shellcheck -e " + exclude_code_list + " %s")
    if has_error is False:
        print("OK: no error detected from shellcheck")
        sys.exit(0)
    else:
        print("ERROR: %s has failed." % (os.path.basename(__file__)))
        sys.exit(1)
## File : enforce_shellcheck.py ends
