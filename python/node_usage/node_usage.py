#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2017 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : node_usage.py
## Author : Denny <denny@dennyzhang.com>
## Description : Show OS and process resource usage: CPU, RAM and disk
## Sample:
##         python ./node_usage.py
## --
## Created : <2017-05-22>
## Updated: Time-stamp: <2017-06-02 15:34:58>
##-------------------------------------------------------------------
import os, sys
import psutil
import argparse
import json
import socket

# http://www.programcreek.com/python/example/53878/psutil.disk_usage
def show_disk_usage(output_dict):
    my_dict = {}
    i = 0
    for part in psutil.disk_partitions(all=False):
        dist_entry_dict = {}
        usage = psutil.disk_usage(part.mountpoint)
        total_gb = usage.total/(1024*1024*1024)
        used_gb = usage.used/(1024*1024*1024)
        free_gb = usage.free/(1024*1024*1024)
        dist_entry_dict["partition"] = part.mountpoint
        dist_entry_dict["total_gb"] = "{:.2f}".format(total_gb)
        dist_entry_dict["used_gb"] = "{:.2f}".format(used_gb)
        dist_entry_dict["free_gb"] = "{:.2f}".format(free_gb)
        dist_entry_dict["used_percentage"] = "{:.2f}".format(usage.percent)
        my_dict[i] = dist_entry_dict
        i = i + 1
    output_dict["disk"] = my_dict
    return (True, output_dict)

# https://stackoverflow.com/questions/276052/how-to-get-current-cpu-and-ram-usage-in-python
def show_cpu_usage(output_dict):
    # TODO: be done
    # print("CPU Utilization. %s" % (psutil.cpu_percent()))
    return (True, output_dict)

def show_memory_usage(output_dict):
    my_dict = {}
    memory_usage = psutil.virtual_memory()
    memory_total_mb = memory_usage.total/(1024*1024)
    memory_available_mb = memory_usage.available/(1024*1024)
    memory_buffers_mb = memory_usage.buffers/(1024*1024)
    percent_ratio = (memory_total_mb - memory_available_mb)/memory_total_mb
    my_dict["ram_total_mb"] = "{:.2f}".format(memory_total_mb)
    my_dict["ram_available_mb"] = "{:.2f}".format(memory_available_mb)
    my_dict["ram_buffers_mb"] = "{:.2f}".format(memory_buffers_mb)
    my_dict["used_percentage"] = "{:.2f}".format(percent_ratio)

    output_dict["ram"] = my_dict
    return (True, output_dict)

def get_process_usage(output_dict, pid_file):
    if os.path.exists(pid_file) is False:
        print("ERROR: pid file(%s) doesn't exist" % (pid_file))
        return (False, output_dict)

    pid = ""
    with open(pid_file) as f:
        pid = f.readlines()
        pid = int(pid[0])

    py = psutil.Process(pid)
    # TODO: implement the logic
    memoryUse = py.memory_info()[0]/2.**30

    return (True, output_dict)

def show_usage(pid_file):
    output_dict = {}
    output_dict['hostname'] = socket.gethostname()

    is_ok = True
    if pid_file is not None:
        (status, output_dict) = get_process_usage(output_dict, pid_file)
        if status is False:
            is_ok = False

    (status, output_dict) = show_memory_usage(output_dict)
    if status is False:
        is_ok = False

    (status, output_dict) = show_disk_usage(output_dict)
    if status is False:
        is_ok = False

    (status, output_dict) = show_cpu_usage(output_dict)
    if status is False:
        is_ok = False

    # show output as json
    print json.dumps(output_dict)

    return is_ok

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--pid_file', required=False, \
                        help="Process pidfile. If not given, the check of process resource usage will be skipped", type=str)
    l = parser.parse_args()
    pid_file = l.pid_file

    if show_usage(pid_file) is False:
        print "ERROR: fail to get node_usage.py"
        sys.exit(1)
    else:
        sys.exit(0)
## File : node_usage.py ends
