# -*- coding: utf-8 -*-
#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2017 DennyZhang.com
## Licensed under MIT 
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : check_out_of_memory.py
## Author : Denny <denny@dennyzhang.com>
## Description : Detect whether OOM(Out Of Memory) has happened in the previous several hours
## --
## Created : <2017-02-28>
## Updated: Time-stamp: <2017-03-14 14:00:21>
##-------------------------------------------------------------------
# Check: http://www.dennyzhang.com/monitor_oom/
import argparse
import sys

NAGIOS_OK_ERROR=0
NAGIOS_EXIT_ERROR=2

def get_oom_entry():
    oom_list = []
    return oom_list

def filter_entry_by_datetime(oom_list, datetime, offset_hours):
    ret_list = []
    return ret_list

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--es_host', required=False, \
                        help="server ip or hostname for elasticsearch instance. Default value is ip of eth0", type=str)
## File : check_out_of_memory.py ends
