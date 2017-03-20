# -*- coding: utf-8 -*-
#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2017 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : detect_process_stale_fd.py
## Author : Denny <denny@dennyzhang.com>
## Description :
##    Check all ES indices have more than $min_replica_count replicas
## --
## Created : <2017-02-24>
## Updated: Time-stamp: <2017-03-20 15:27:22>
##-------------------------------------------------------------------
import argparse
import requests
import sys
import socket
import re

NAGIOS_OK_ERROR=0
NAGIOS_EXIT_ERROR=2

def get_processid_by_pidfile(pidfile):
    pid = -1
    with open(pidfile,'r') as f:
        pid = f.readlines()

if __name__ == '__main__':
    # get parameters from users
    parser = argparse.ArgumentParser()
    parser.add_argument('--es_host', required=False, \
                        help="server ip or hostname for elasticsearch instance. Default value is ip of eth0", type=str)
    parser.add_argument('--es_port', default='9200', required=False, \
                        help="server port for elasticsearch instance", type=str)
    parser.add_argument('--es_pattern_regexp', required=False, default='', \
                        help="ES index name pattern. Only ES indices with matched pattern will be examined", type=str)
    parser.add_argument('--min_replica_count', default=1, required=False, \
                        help="minimal replica each elasticsearch index should have", type=str)
    l = parser.parse_args()

    es_port = l.es_port
    min_replica_count = int(l.min_replica_count)
    es_pattern_regexp = l.es_pattern_regexp
    es_host = l.es_host

    if min_replica_count == 0:
        print "OK: skip the check, since the given min_replica_count is 0"
        sys.exit(NAGIOS_OK_ERROR)
        
    # get ip of eth0, if es_host is not given
    if es_host is None:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        es_host = s.getsockname()[0]

    es_index_list = get_es_index_list(es_host, es_port)

    failed_index_list = confirm_es_replica_count(es_host, es_port, es_index_list, \
                                                 min_replica_count, es_pattern_regexp)

    if len(failed_index_list) != 0:
        print "ERROR: Below indices don't have enough replica:\n%s" % \
            (",".join(failed_index_list))
        sys.exit(NAGIOS_EXIT_ERROR)
    else:
        print "OK: all ES indices have no less than %d replicas" % (min_replica_count)
        sys.exit(NAGIOS_OK_ERROR)
## File : detect_process_stale_fd.py ends
