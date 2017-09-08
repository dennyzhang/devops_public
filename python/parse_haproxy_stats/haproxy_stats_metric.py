#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT 
##   https://www.dennyzhang.com/wp-content/mit_license.txt
##
## File : haproxy_stats_metric.py
## Author : Denny <contact@dennyzhang.com>
## Description : A Python module to parse haproxy stats
##
## More reading: https://www.dennyzhang.com/haproxy_stats
##
## --
## Created : <2016-10-04>
## Updated: Time-stamp: <2017-09-07 21:36:06>
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
        print("%s %s %s %s" % (timestamp, 'HTTPCode', field, haproxy_dict[field]))

    for field in 'scur,smax'.split(','):
        print("%s %s %s %s" % (timestamp, 'SessionThread', field, haproxy_dict[field]))

    for field in 'ctime,rtime,ttime'.split(','):
        print("%s %s %s %s" % (timestamp, 'AvgTime', field, haproxy_dict[field]))

# python ./haproxy_stats_metric.py --haproxy_stats_cmd "echo 'show stat' | nc -U /var/run/haproxy/admin.sock | grep 'backend-https,BACKEND'"
if __name__=='__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--haproxy_stats_cmd', default = '', \
                        required = True, help = "Command to get haproxy stats", type=str)
    l = parser.parse_args()

    cmd = l.haproxy_stats_cmd
    status, output = commands.getstatusoutput(cmd)
    if(status == 0):
        stat_output = output.strip()
        timestamp = get_timestamp()
        haproxy_stats_metric(stat_output, timestamp)
    else:
        msg = "Error to run cmd: %s\n. output: %s" % (cmd, output)
        raise Exception(msg)
## File : haproxy_stats_metric.py ends
