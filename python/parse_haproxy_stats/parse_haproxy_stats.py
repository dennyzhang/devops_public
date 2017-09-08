#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT 
##   https://www.dennyzhang.com/wp-content/mit_license.txt
##
## File : parse_haproxy_stats.py
## Author : Denny <contact@dennyzhang.com>
## Description : A Python module to parse haproxy stats
##
## More reading: https://www.dennyzhang.com/haproxy_stats
##
## --
## Created : <2016-10-04>
## Updated: Time-stamp: <2017-09-07 21:36:06>
##-------------------------------------------------------------------
# Name haproxy status output field by field
HEADER_FIELD_NAMES = 'pxname,svname,qcur,qmax,scur,smax,slim,stot,bin,bout,dreq,dresp,ereq,econ,eresp,wretr,wredis,status,weight,act,bck,chkfail,chkdown,lastchg,downtime,qlimit,pid,iid,sid,throttle,lbtot,tracked,type,rate,rate_lim,rate_max,check_status,check_code,check_duration,hrsp_1xx,hrsp_2xx,hrsp_3xx,hrsp_4xx,hrsp_5xx,hrsp_other,hanafail,req_rate,req_rate_max,req_tot,cli_abrt,srv_abrt,comp_in,comp_out,comp_byp,comp_rsp,lastsess,last_chk,last_agt,qtime,ctime,rtime,ttime,'

def parse_haproxy_stats(stat_output):
    l = stat_output.split(',')
    field_name_list = HEADER_FIELD_NAMES.split(',')
    haproxy_dict = {}

    i = 0
    for item in l:
        field_name = field_name_list[i]
        haproxy_dict[field_name] = item
        i = i + 1
    return haproxy_dict

def test_haproxy_stats():
    # Test Example: parse output and print critical field
    stat_output = "backend-https,BACKEND,0,0,0,9,200,276978,2746128724,678805060,0,0,,47,6,3,0,UP,1,1,0,,22,101965,3120,,1,5,0,,276932,,1,0,,27,,,,0,239978,7435,29459,102,4,,,,,16,0,0,0,0,0,106,,,0,57,31,478,"
    haproxy_dict = parse_haproxy_stats(stat_output)
    field_list = 'hrsp_2xx,hrsp_4xx,hrsp_5xx,scur,smax'
    for field in field_list.split(','):
        print("%s: %s" % (field, haproxy_dict[field]))

if __name__=='__main__':
    test_haproxy_stats()
## File : parse_haproxy_stats.py ends
