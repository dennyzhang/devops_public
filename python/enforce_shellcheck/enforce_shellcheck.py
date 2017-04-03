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
## Updated: Time-stamp: <2017-04-02 21:05:28>
##-------------------------------------------------------------------
import argparse
import sys

def find_sh_files(working_dir, shellcheck_ignore_file):
    l = []

def run_shell_check(sh_file_list, exclude_code_list):
    l = []

if __name__ == '__main__':
    # get parameters from users
    parser = argparse.ArgumentParser()
    parser.add_argument('--code_dir', required=True, \
                        help="Source code directory to be scanned", type=str)
    parser.add_argument('--shellcheck_ignore_file', required=False, \
                        help="file pattern listed in the file will be skipped for scan", type=str)
    parser.add_argument('--exclude_code_list', required=False, \
                        default="SC1090,SC1091,SC2154,SC2001,SC2002,SC2181", \
                        help="shellcheck code to be skipped", type=str)
    l = parser.parse_args()
    
    shellcheck_ignore_file = l.shellcheck_ignore_file
    exclude_code_list = l.exclude_code_list
## File : enforce_shellcheck.py ends
