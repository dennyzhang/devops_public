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
## Updated: Time-stamp: <2017-04-09 22:04:46>
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

################################################################################
def run_check(file_list, check_pattern):
    has_error = False
    for fname in file_list:
        check_command = check_pattern % (fname)
        print "Run check command: %s" % (check_command)
        p = subprocess.Popen(check_command, shell=True)
        if p.returncode != 0:
            has_error = True
            while True:
                out = p.stderr.read(1)
                if out == '' and p.poll() != None:
                    break
                if out != '':
                    sys.stdout.write(out)
                    sys.stdout.flush()
    return has_error
################################################################################
#
# wget -O /tmp/enforce_pylint_check.py https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v5/python/enforce_pylint_check/enforce_pylint_check.py
# python /tmp/enforce_pylint_check.py --code_dir devops_code/devops_public
################################################################################
if __name__ == '__main__':
    # get parameters from users
    parser = argparse.ArgumentParser()
    parser.add_argument('--code_dir', required=True, \
                        help="Source code directory to be scanned", type=str)
    parser.add_argument('--check_ignore_file', required=False, \
                        help="file pattern listed in the file will be skipped for scan", type=str)
    l = parser.parse_args()
    
    code_dir = l.code_dir
    check_ignore_file = l.check_ignore_file

    file_list = find_files_by_postfix(code_dir, ".py")
    file_list = ignore_files(file_list, check_ignore_file)
    has_error = run_check(file_list, "pylint -E %s")
    if has_error is True:
        sys.exit(0)
    else:
        print "ERROR: pylint_check has failed."
        sys.exit(1)
## File : enforce_pylint_check.py ends
