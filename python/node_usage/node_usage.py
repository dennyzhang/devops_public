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
## Updated: Time-stamp: <2017-06-03 14:05:23>
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
    sum_total_gb = 0
    sum_used_gb = 0
    sum_free_gb = 0
    for part in psutil.disk_partitions(all=False):
        dist_entry_dict = {}
        usage = psutil.disk_usage(part.mountpoint)
        total_gb = float(usage.total)/(1024*1024*1024)
        used_gb = float(usage.used)/(1024*1024*1024)
        free_gb = float(usage.free)/(1024*1024*1024)

        sum_total_gb = sum_total_gb + total_gb
        sum_used_gb = sum_used_gb + used_gb
        sum_free_gb = sum_free_gb + free_gb

        dist_entry_dict["partition"] = part.mountpoint
        dist_entry_dict["total_gb"] = "{:.2f}".format(total_gb)
        dist_entry_dict["used_gb"] = "{:.2f}".format(used_gb)
        dist_entry_dict["free_gb"] = "{:.2f}".format(free_gb)
        current_used_percentage = float(dist_entry_dict["used_gb"])*100/float(dist_entry_dict["total_gb"])
        percent_ratio = "{:.2f}".format(current_used_percentage) + "%"
        dist_entry_dict["used_percentage"] = percent_ratio

        if "used_percentage" in my_dict:
            my_dict["used_percentage"] = "%s, %s %s(%sgb/%sgb)" % \
                                         (my_dict["used_percentage"], \
                                          part.mountpoint, percent_ratio,
                                          dist_entry_dict["used_gb"], dist_entry_dict["total_gb"])
        else:
            my_dict["used_percentage"] = "%s %s(%sgb/%sgb)" % \
                                         (part.mountpoint, percent_ratio, \
                                          dist_entry_dict["used_gb"], dist_entry_dict["total_gb"])

        my_dict["disk_%d" % i] = dist_entry_dict
        i = i + 1

    my_dict["total_gb"] = "{:.2f}".format(sum_total_gb)
    my_dict["used_gb"] = "{:.2f}".format(sum_used_gb)
    my_dict["free_gb"] = "{:.2f}".format(sum_free_gb)

    output_dict["disk"] = my_dict
    return (True, output_dict)

def show_memory_usage(output_dict):
    my_dict = {}
    memory_usage = psutil.virtual_memory()
    memory_total_mb = float(memory_usage.total)/(1024*1024)
    memory_used_mb = float(memory_usage.used)/(1024*1024)
    memory_available_mb = float(memory_usage.available)/(1024*1024)
    memory_buffers_mb = float(memory_usage.buffers)/(1024*1024)
    my_dict["ram_total_mb"] = "{:.2f}".format(memory_total_mb)
    my_dict["ram_used_mb"] = "{:.2f}".format(memory_used_mb)
    my_dict["ram_available_mb"] = "{:.2f}".format(memory_available_mb)
    my_dict["ram_buffers_mb"] = "{:.2f}".format(memory_buffers_mb)
    percent_ratio = float(my_dict["ram_used_mb"])*100/float(my_dict["ram_total_mb"])
    my_dict["used_percentage"] = "%s(%smb/%smb)" % \
                                 ("{:.2f}".format(percent_ratio) + "%", \
                                  my_dict["ram_used_mb"], my_dict["ram_total_mb"])

    output_dict["ram"] = my_dict
    return (True, output_dict)

# https://stackoverflow.com/questions/276052/how-to-get-current-cpu-and-ram-usage-in-python
def show_cpu_usage(output_dict):
    # TODO: be done
    # print("CPU Utilization. %s" % (psutil.cpu_percent()))
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
