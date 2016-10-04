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
## Updated: Time-stamp: <2016-10-04 20:15:33>
##-------------------------------------------------------------------
import parse_haproxy_stats
import datetime
def get_timestamp():
    return "[%s +0000]" % \
        (datetime.datetime.utcnow().strftime("%d/%b/%Y:%H:%M:%S"))

def haproxy_stats_metric(stat_output, timestamp):
    haproxy_dict = parse_haproxy_stats.parse_haproxy_stats(stat_output)

    for field in 'hrsp_2xx,hrsp_4xx,hrsp_5xx'.split(','):
        print "%s %s %s %s" % (timestamp, 'HTTPCode', field, haproxy_dict[field])

    for field in 'scur,smax'.split(','):
        print "%s %s %s %s" % (timestamp, 'HTTPCode', field, haproxy_dict[field])

if __name__=='__main__':
    stat_output = "backend-https,BACKEND,0,0,0,9,200,276978,2746128724,678805060,0,0,,47,6,3,0,UP,1,1,0,,22,101965,3120,,1,5,0,,276932,,1,0,,27,,,,0,239978,7435,29459,102,4,,,,,16,0,0,0,0,0,106,,,0,57,31,478,"
    timestamp = get_timestamp()
    haproxy_stats_metric(stat_output, timestamp)
## File : haproxy_stats_metric.py ends
