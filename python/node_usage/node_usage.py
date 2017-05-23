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
## Updated: Time-stamp: <2017-05-22 23:07:59>
##-------------------------------------------------------------------
import psutil

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

# https://stackoverflow.com/questions/276052/how-to-get-current-cpu-and-ram-usage-in-python
def show_cpu_usage():
    # TODO: wrong calculation
    print("CPU Utilization. %s" % (psutil.cpu_percent()))

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

def get_process_usage(pid):
    py = psutil.Process(pid)
    # memory use in GB
    memoryUse = py.memory_info()[0]/2.**30

def show_usage():
    show_memory_usage()
    show_disk_usage()
    show_cpu_usage()

if __name__ == '__main__':
    show_usage()
## File : node_usage.py ends
