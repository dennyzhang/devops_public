# -*- coding: utf-8 -*-
#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2017 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : enforce_pylint_check.py
## Author : Denny <denny@dennyzhang.com>
## Description :
## --
## Created : <2017-04-02>
## Updated: Time-stamp: <2017-04-09 21:49:23>
##-------------------------------------------------------------------
import argparse
import sys
import os

def find_files_by_postfix(folder_check, filename_postfix):
    l = []
    for root, dirs, files in os.walk(folder_check):
        for file in files:
            if file.endswith(filename_postfix):
                l.append(os.path.join(root, file))
    return l

def ignore_files(file_list, ignore_file_list):
    # TODO
    return file_list

################################################################################
def run_pylint_check(sh_file_list):
    # TODO: to be implemented
    l = []
    return True

if __name__ == '__main__':
    # get parameters from users
    parser = argparse.ArgumentParser()
    parser.add_argument('--code_dir', required=True, \
                        help="Source code directory to be scanned", type=str)
    parser.add_argument('--pylint_check_ignore_file', required=False, \
                        help="file pattern listed in the file will be skipped for scan", type=str)
    l = parser.parse_args()
    
    code_dir = l.code_dir
    pylint_check_ignore_file = l.pylint_check_ignore_file

    file_list = find_files_by_postfix(code_dir, ".py")
    # TODO
    print file_list

    has_pass = run_pylint_check(file_list)
    if has_pass is True:
        sys.exit(0)
    else:
        print "ERROR: pylint_check has failed."
        sys.exit(1)
## File : enforce_pylint_check.py ends
