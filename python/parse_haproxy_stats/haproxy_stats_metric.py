# -*- coding: utf-8 -*-
#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT 
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : haproxy_stats_metric.py
## Author : Denny <denny@dennyzhang.com>
## Description : A Python module to parse haproxy stats
## --
## Created : <2016-10-04>
## Updated: Time-stamp: <2016-10-04 20:21:46>
##-------------------------------------------------------------------
import parse_haproxy_stats
import datetime
import argparse
import commands

def get_timestamp():
    return "[%s +0000]" % \
        (datetime.datetime.utcnow().strftime("%d/%b/%Y:%H:%M:%S"))

def haproxy_stats_metric(stat_output, timestamp):
    haproxy_dict = parse_haproxy_stats.parse_haproxy_stats(stat_output)

    for field in 'hrsp_2xx,hrsp_4xx,hrsp_5xx'.split(','):
        print "%s %s %s %s" % (timestamp, 'HTTPCode', field, haproxy_dict[field])

    for field in 'scur,smax'.split(','):
        print "%s %s %s %s" % (timestamp, 'HTTPCode', field, haproxy_dict[field])

# python ./haproxy_stats_metric.py --haproxy_stats_cmd "echo 'show stat' | nc -U /var/run/haproxy/admin.sock | grep 'backend-https,BACKEND'"
if __name__=='__main__':
    parser = argparse.ArgumentParser()
    default_haproxy_stats_cmd \
        = "echo 'show stat' | nc -U /var/run/haproxy/admin.sock | grep 'backend-https,BACKEND'"
    parser.add_argument('--haproxy_stats_cmd', default=default_haproxy_stats_cmd, \
                        required=True, help="Command to get haproxy stats", type=str)

    l = parser.parse_args()
    cmd = l.default_haproxy_stats_cmd
    status, output = commands.getstatusoutput(cmd)
    if(status == 0):
        stat_output = output.strip()
        timestamp = get_timestamp()
        haproxy_stats_metric(stat_output, timestamp)
    else:
        msg = "Error to run cmd: %s\n. output: %s" % (cmd, output)
        raise Exception(msg)
## File : haproxy_stats_metric.py ends
