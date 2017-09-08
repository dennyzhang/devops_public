# -*- coding: utf-8 -*-
#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2017 DennyZhang.com
## Licensed under MIT 
##   https://www.dennyzhang.com/wp-content/mit_license.txt
##
## File : check_out_of_memory.py
## Author : Denny <contact@dennyzhang.com>
## Description : Detect whether OOM(Out Of Memory) has happened in the previous several hours
## --
## Created : <2017-02-28>
## Updated: Time-stamp: <2017-09-07 21:36:07>
##-------------------------------------------------------------------
# Check: https://www.dennyzhang.com/monitor_oom
import argparse
import platform
import sys
import commands
import time

NAGIOS_OK_ERROR=0
NAGIOS_EXIT_ERROR=2

def get_time_seconds_from_dmsg(dmsg_entry):
    # From: [Sat Mar 11 00:19:44 2017] java invoked oom-killer: gfp_mask=0x26000c0, order=2, oom_score_adj=-17
    # To: 1489191584
    l = dmsg_entry.split("] ")
    date = l[0][1:]
    return int(time.mktime(time.strptime(date,'%a %b %d %H:%M:%S %Y')))

def get_oom_entry():
    # Sample output
    '''
root@bematech-es-1:~# dmesg -T | grep -i oom
[Sat Mar 11 00:19:44 2017] java invoked oom-killer: gfp_mask=0x26000c0, order=2, oom_score_adj=-17
[Sat Mar 11 00:19:44 2017]  [<ffffffff81188b35>] oom_kill_process+0x205/0x3d0
[Sat Mar 11 00:19:44 2017] [ pid ]   uid  tgid total_vm      rss nr_ptes nr_pmds swapents oom_score_adj name
    '''
    command = 'dmesg -T | grep -i oom'
    _status, output = commands.getstatusoutput(command)
    return output.split("\n")

def filter_entry_by_datetime(oom_list, hours_to_check):
    ret_list = []
    seconds_per_hour = 3600
    current_seconds = int(round(time.time()))
    for entry in oom_list:
        entry_seconds = get_time_seconds_from_dmsg(entry)
        if current_seconds <= entry_seconds + hours_to_check * seconds_per_hour:
            ret_list.append(entry)
    return ret_list

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--hours_to_check', required=False, default=10, type=int, \
                        help="Only check oom entries happen within previous several hours")
    l = parser.parse_args()
    hours_to_check = l.hours_to_check

    # Check OS release
    if platform.linux_distribution()[0] != 'Ubuntu':
        print("ERROR: current only support Ubuntu OS.")
        sys.exit(NAGIOS_EXIT_ERROR)

    oom_list = get_oom_entry()
    matched_oom_list = filter_entry_by_datetime(oom_list, hours_to_check)
    if len(matched_oom_list) == 0:
        print("OK: No OOM has happened in previous %d hours." % (hours_to_check))
    else:
        print("ERROR: OOM has happened in previous %d hours.\n%s" % \
            (hours_to_check, "\n".join(matched_oom_list)))
        sys.exit(NAGIOS_EXIT_ERROR)

    sys.exit(NAGIOS_OK_ERROR)
## File : check_out_of_memory.py ends
