#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2017 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : node_usage.py
## Author : Denny <denny@dennyzhang.com>
## Description : Show OS and process resource usage: CPU, RAM and disk
## --
## Created : <2017-05-22>
## Updated: Time-stamp: <2017-05-22 22:34:32>
##-------------------------------------------------------------------
import psutil

def get_os_usage():
    cpu_percent = psutil.cpu_percent()
    memory_usage = psutil.virtual_memory()
    return (cpu_percent, memory_usage)

def get_process_usage(pid):
    py = psutil.Process(pid)
    # memory use in GB
    memoryUse = py.memory_info()[0]/2.**30

def show_usage():
    (cpu_percent, memory_usage) = get_os_usage()
    memory_total_mb = memory_usage.total/(1024*1024)
    memory_available_mb = memory_usage.available/(1024*1024)
    memory_buffers_mb = memory_usage.buffers/(1024*1024)
    print("CPU percent: %f." % (cpu_percent))
    print("Memory Summary. Available: %f, buffered: %f, total: %f" % \
          (memory_total_mb, memory_available_mb, memory_buffers_mb))

if __name__ == '__main__':
    show_usage()
## File : node_usage.py ends
