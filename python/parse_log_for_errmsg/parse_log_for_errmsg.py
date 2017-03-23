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
## Updated: Time-stamp: <2017-03-23 14:36:56>
##-------------------------------------------------------------------
import argparse
import sys
NAGIOS_OK_ERROR=0
NAGIOS_EXIT_ERROR=2

def filter_log_by_errmsg(log_folder, err_patterns, logfile_postfix = ".log"):
    err_msgs = ""
    return err_msgs

def filter_errmsg_by_whitelist(errmsgs, whitelist_patterns, separator = "|"):
    ret_msg = ""
    return ret_msg

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
    err_patterns = l.err_patterns
    whitelist_patterns = l.whitelist_patterns

    err_msgs = filter_log_by_errmsg(log_folder, err_patterns)
    if whitelist_patterns != "":
        err_msgs = filter_errmsg_by_whitelist(err_patterns, whitelist_patterns)
    if err_msgs != "":
        print "ERROR: unexpected errors/exceptions are found under %s. errmsg: %s" % (log_folder, err_msgs)
        sys.exit(NAGIOS_EXIT_ERROR)
    else:
        print "OK: no unexpected errors/exceptions are found under %s." % (log_folder)
        sys.exit(NAGIOS_OK_ERROR)
## File : parse_log_for_errmsg.py ends
