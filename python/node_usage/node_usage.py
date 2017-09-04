#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2017 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : node_usage.py
## Author : Denny <contact@dennyzhang.com>
## Description : Show OS and process resource usage: CPU, RAM and disk
## Sample:
##         python ./node_usage.py
##             {"disk": {"disk_0": {"free_gb": "170.42", "total_gb": "377.83", "partition": "/", "used_percentage": "49.82%", "used_gb": "188.22"}, "free_gb": "170.42", "total_gb": "377.83", "used_percentage": "/ 49.82%(188.22gb/377.83gb)", "used_gb": "188.22"}, "hostname": "dennytest", "ram": {"used_percentage": "8.79%(2.07gb/23.55gb)", "ram_buffers_gb": "8.17", "ram_available_gb": "21.40", "ram_total_gb": "23.55", "ram_used_gb": "2.07"}}
##
## --
## Created : <2017-05-22>
## Updated: Time-stamp: <2017-09-04 18:55:31>
##-------------------------------------------------------------------
import os, sys
import psutil
import argparse
import json
import socket
import subprocess
import json

# https://stackoverflow.com/questions/136168/get-last-n-lines-of-a-file-with-python-similar-to-tail
def tail(f, lines=20):
    total_lines_wanted = lines

    BLOCK_SIZE = 1024
    f.seek(0, 2)
    block_end_byte = f.tell()
    lines_to_go = total_lines_wanted
    block_number = -1
    blocks = [] # blocks of size BLOCK_SIZE, in reverse order starting
                # from the end of the file
    while lines_to_go > 0 and block_end_byte > 0:
        if (block_end_byte - BLOCK_SIZE > 0):
            # read the last block we haven't yet read
            f.seek(block_number*BLOCK_SIZE, 2)
            blocks.append(f.read(BLOCK_SIZE))
        else:
            # file too small, start from begining
            f.seek(0,0)
            # only read what was not read
            blocks.append(f.read(block_end_byte))
        lines_found = blocks[-1].count('\n')
        lines_to_go -= lines_found
        block_end_byte -= BLOCK_SIZE
        block_number -= 1
    all_read_text = ''.join(reversed(blocks))
    return '\n'.join(all_read_text.splitlines()[-total_lines_wanted:])

def get_ip_address():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.connect(("8.8.8.8", 80))
    return s.getsockname()[0]

# http://www.programcreek.com/python/example/53878/psutil.disk_usage
def get_disk_usage(output_dict):
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

def get_memory_usage(output_dict):
    my_dict = {}
    memory_usage = psutil.virtual_memory()
    memory_total_gb = float(memory_usage.total)/(1024*1024*1024)
    memory_used_gb = float(memory_usage.used)/(1024*1024*1024)
    memory_available_gb = float(memory_usage.available)/(1024*1024*1024)
    memory_buffers_gb = float(memory_usage.buffers)/(1024*1024*1024)
    my_dict["ram_total_gb"] = "{:.2f}".format(memory_total_gb)
    my_dict["ram_used_gb"] = "{:.2f}".format(memory_used_gb)
    my_dict["ram_available_gb"] = "{:.2f}".format(memory_available_gb)
    my_dict["ram_buffers_gb"] = "{:.2f}".format(memory_buffers_gb)
    percent_ratio = float(my_dict["ram_used_gb"])*100/float(my_dict["ram_total_gb"])
    my_dict["used_percentage"] = "%s(%sgb/%sgb)" % \
                                 ("{:.2f}".format(percent_ratio) + "%", \
                                  my_dict["ram_used_gb"], my_dict["ram_total_gb"])

    output_dict["ram"] = my_dict

# https://stackoverflow.com/questions/276052/how-to-get-current-cpu-and-ram-usage-in-python
def get_cpu_usage(output_dict):
    p = psutil.Process(os.getpid())
    output_dict["cpu_count"] = psutil.cpu_count()
    with open('/proc/loadavg') as f:
        content = f.readlines()
    output_dict["cpu_load"] = content[0].rstrip("\n")

def get_service_status(output_dict, service_command):
    try:
        command_output = \
                         subprocess.check_output(service_command.split(" "), \
                                                 shell = True, stderr=subprocess.STDOUT)
    except subprocess.CalledProcessError as grepexc:
        command_output = "Error. code: %d, errmsg: %s" % (grepexc.returncode, grepexc.output)
    output_dict["service_status"] = "%s:\n%s" % (service_command, command_output.decode("utf-8"))

def tail_log_file(output_dict, log_file, tail_log_num):
    log_message = "[Log] tail -n %d %s:" % (tail_log_num, log_file)
    try:
        with open(log_file,'r') as f:
            message = tail(f, tail_log_num)
            # Escape double quotes for JSON
            message = json.dumps(message)
            log_message = "%s\n%s" % (log_message, message)
    except Exception as e:
        log_message = "%s\nFailed to tail log: %s" % (log_message, e)
    output_dict["tail_log_file"] = log_message

def show_usage(service_command, log_file, tail_log_num):
    output_dict = {}
    output_dict['hostname'] = socket.gethostname()
    output_dict['ipaddress_eth0'] = get_ip_address()

    if service_command is not None:
        get_service_status(output_dict, service_command)

    if log_file is not None:
        tail_log_file(output_dict, log_file, tail_log_num)

    get_memory_usage(output_dict)
    get_disk_usage(output_dict)
    get_cpu_usage(output_dict)

    # show output as json
    print(json.dumps(output_dict))

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--check_service_command', required=False, \
                        help="What command to check service status. If not given, service check will be skipped", type=str)
    parser.add_argument('--log_file', required=False, \
                        help="Tail log file", type=str)
    parser.add_argument('--tail_log_num', required=False, default=30,\
                        help="Tail last multiple lines of log file", type=int)
    l = parser.parse_args()
    show_usage(l.check_service_command, l.log_file, l.tail_log_num)
## File : node_usage.py ends
