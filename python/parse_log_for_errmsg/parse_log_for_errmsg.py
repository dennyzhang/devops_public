# -*- coding: utf-8 -*-
#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2017 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : parse_log_for_errmsg.py
## Author : Denny <denny@dennyzhang.com>
## Description :
## --
## Created : <2017-03-23>
## Updated: Time-stamp: <2017-03-23 15:38:13>
##-------------------------------------------------------------------
import argparse
import sys
import glob
import os

NAGIOS_OK_ERROR=0
NAGIOS_EXIT_ERROR=2
MAX_FILE_SIZE = 1024 * 1024 * 1024 # 1GB
SEPARATOR = "|"

def filter_log_by_errmsg(log_folder, err_pattern_list, \
                         logfile_postfix = ".log"):
    err_msg_list = []

    # TODO: Performance tunning: For files bigger than GB, the script won't work
    for f in glob.glob("%s/*%s" % (log_folder, logfile_postfix)):
        if os.stat(f).st_size > MAX_FILE_SIZE:
            print "ERROR: Unsupported large files. %f is larger than %s." % (f, MAX_FILE_SIZE)
            sys.exit(NAGIOS_EXIT_ERROR)
        for line in f:
            for err_pattern in err_pattern_list:
                if err_pattern in line:
                    err_msg_list.append(line)
    return err_msg_list

def filter_errmsg_by_whitelist(err_msg_list, whitelist_pattern_list):
    ret_msg_list = []
    for line in err_msg_list:
        for whitelist_pattern in whitelist_pattern_list:
            if whitelist_pattern in line:
                continue
            ret_msg_list.append(line)
    return ret_msg_list

# Sample: ./parse_log_for_errmsg.py \
#                --log_folder /opt/mymdm/logs
#                --err_patterns "error|exception" \
#                --whitelist_patterns "route53|Maybe document|Not found template"
if __name__ == '__main__':
    # get parameters from users
    parser = argparse.ArgumentParser()
    parser.add_argument('--log_folder', required=True, type=str, \
                        help="Which log folder to check")
    parser.add_argument('--err_patterns', default='error|exception', required=False, \
                        help="Interested error patterns. If multiple, we should use | to separate them")
    parser.add_argument('--whitelist_patterns', default='', required=False, \
                        help="What white patterns are expected to be safe")
    l = parser.parse_args()

    log_folder = l.log_folder
    err_pattern_list = l.err_patterns.split(SEPARATOR)
    whitelist_pattern_list = l.whitelist_patterns.split(SEPARATOR)

    err_msg_list = filter_log_by_errmsg(log_folder, err_pattern_list)
    if len(whitelist_pattern_list) != 0:
        err_msg_list = filter_errmsg_by_whitelist(err_msg_list, whitelist_pattern_list)
    if err_msg_list != "":
        print "ERROR: unexpected errors/exceptions are found under %s. errmsg: %s" % \
            (log_folder, "\n".join(err_msg_list))
        sys.exit(NAGIOS_EXIT_ERROR)
    else:
        print "OK: no unexpected errors/exceptions are found under %s." % (log_folder)
        sys.exit(NAGIOS_OK_ERROR)
## File : parse_log_for_errmsg.py ends
