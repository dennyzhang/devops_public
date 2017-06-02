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
## Updated: Time-stamp: <2017-06-02 14:22:53>
##-------------------------------------------------------------------
import os, sys
import psutil
import argparse

# http://www.programcreek.com/python/example/53878/psutil.disk_usage
def show_disk_usage():
    print("Disk Utilization.")
    for part in psutil.disk_partitions(all=False):
        usage = psutil.disk_usage(part.mountpoint)
        total_gb = usage.total/(1024*1024*1024)
        used_gb = usage.used/(1024*1024*1024)
        free_gb = usage.free/(1024*1024*1024)
        percent_ratio_str = "Used ratio: %s" % "{:.2f}".format(usage.percent) + "%"
        print("\tParition:%s, %s, Total: %sGB, Used: %sGB, Free:%sGB." % \
              (part.mountpoint, percent_ratio_str, "{:.2f}".format(total_gb), "{:.2f}".format(used_gb), \
               "{:.2f}".format(free_gb)))
    return True

# https://stackoverflow.com/questions/276052/how-to-get-current-cpu-and-ram-usage-in-python
def show_cpu_usage():
    # TODO: wrong calculation
    print("CPU Utilization. %s" % (psutil.cpu_percent()))
    return True

def show_memory_usage():
    memory_usage = psutil.virtual_memory()
    memory_total_mb = memory_usage.total/(1024*1024)
    memory_available_mb = memory_usage.available/(1024*1024)
    memory_buffers_mb = memory_usage.buffers/(1024*1024)
    percent_ratio = (memory_total_mb - memory_available_mb)*100/memory_total_mb
    percent_ratio_str = "Used ratio: %s" % "{:.2f}".format(percent_ratio) + "%"
    print("Memory Utilization. %s, Total: %sMB, Available: %sMB, Buffered: %sMB" % \
          (percent_ratio_str, "{:.2f}".format(memory_total_mb), "{:.2f}".format(memory_available_mb), \
           "{:.2f}".format(memory_buffers_mb)))
    return True

def get_process_usage(pid_file):
    if os.path.exists(pid_file) is False:
        print("ERROR: pid file(%s) doesn't exist" % (pid_file))
        return False

    pid = ""
    with open(pid_file) as f:
        pid = f.readlines()
        pid = int(pid[0])

    py = psutil.Process(pid)
    # TODO: implement the logic
    memoryUse = py.memory_info()[0]/2.**30

    return True

def show_usage(pid_file):
    is_ok = True
    if pid_file is not None:
        if get_process_usage(pid_file) is False:
            is_ok = False

    if show_memory_usage() is False:
        is_ok = False
    if show_disk_usage() is False:
        is_ok = False
    if show_cpu_usage() is False:
        is_ok = False
    return is_ok

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--pid_file', required=False, \
                        help="Process pidfile. If not given, the check of process resource usage will be skipped", type=str)
    l = parser.parse_args()
    pid_file = l.pid_file

    if show_usage(pid_file) is False:
        sys.exit(1)
    else:
        sys.exit(0)
## File : node_usage.py ends
