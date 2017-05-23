#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2017 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : node_usage.py
## Author : Denny <denny@dennyzhang.com>
## Description :
## --
## Created : <2017-05-22>
## Updated: Time-stamp: <2017-05-22 22:25:47>
##-------------------------------------------------------------------
import psutil

def get_os_usage():
    cpu_percent = psutil.cpu_percent()
    memory_usage = psutil.virtual_memory()

def get_process_usage(pid):
    py = psutil.Process(pid)
    # memory use in GB
    memoryUse = py.memory_info()[0]/2.**30

if __name__ == '__main__':
    test()
## File : node_usage.py ends
