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
## Updated: Time-stamp: <2017-03-23 14:08:32>
##-------------------------------------------------------------------
import argparse
def filter_log_by_errmsg(log_foler, err_msg, logfile_postfix = ".log"):
    err_msgs = ""
    return err_msgs

def filter_errmsg_by_whitelist(errmsgs, whitelist_str, separator = "|"):
    ret_msg = ""
    return ret_msg

# Sample: ./parse_log_for_errmsg.py /opt/mymdm/logs "error|exception" "route53|Maybe document|Not found template"
if __name__ == '__main__':
    # get parameters from users
    parser = argparse.ArgumentParser()
    parser.add_argument('--es_host', required=False, \
                        help="server ip or hostname for elasticsearch instance. Default value is ip of eth0", type=str)
    parser.add_argument('--es_port', default='9200', required=False, \
                        help="server port for elasticsearch instance", type=str)
    parser.add_argument('--es_pattern_regexp', required=False, default='', \
                        help="ES index name pattern. Only ES indices with matched pattern will be examined", type=str)
    parser.add_argument('--min_shard_count', default=3, required=False, \
                        help="minimal shard each elasticsearch index should have", type=str)
    l = parser.parse_args()
## File : parse_log_for_errmsg.py ends
