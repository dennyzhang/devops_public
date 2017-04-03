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
## Updated: Time-stamp: <2017-04-02 21:29:39>
##-------------------------------------------------------------------
import argparse
import sys

def find_python_files(working_dir, pylint_check_ignore_file):
    # TODO: to be implemented
    l = []
    return l

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

    file_list = find_python_files(code_dir, pylint_check_ignore_file)
    has_pass = run_pylint_check(file_list)
    if has_pass is True:
        sys.exit(0)
    else:
        print "ERROR: pylint_check has failed."
        sys.exit(1)
## File : enforce_pylint_check.py ends
