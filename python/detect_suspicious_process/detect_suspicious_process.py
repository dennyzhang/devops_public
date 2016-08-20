# -*- coding: utf-8 -*-
#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2015 DennyZhang.com
## File : detect_suspicious_process.py
## Author : DennyZhang.com <denny@dennyzhang.com>
## Description : http://www.dennyzhang.com/suspicious_process/
##        python ./detect_suspicious_process.py
##        python ./detect_suspicious_process.py --whitelist_file /tmp/whitelist.txt
## --
## Created : <2016-01-15>
## Updated: Time-stamp: <2016-08-20 11:17:50>
##-------------------------------------------------------------------
import argparse
import subprocess
import os, sys

################################################################################
default_white_list = '''
/sbin/getty -.*
dbus-daemon .*
 acpid -c /etc/acpi/events -s /var/run/acpid.socket$
 atd$
 cron$
 /lib/systemd/systemd-udevd --daemon$
 /lib/systemd/systemd-logind$
 dbus-daemon --system --fork$
 /usr/sbin/sshd -D$
 rsyslogd$
 /usr/sbin/mysqld$
 /usr/sbin/apache2 -k start$
'''

def get_nonkernel_process():
    command = "sudo ps --ppid 2 -p 2 -p 1 --deselect " + \
              "-o uid,pid,rss,%cpu,command " + \
              "--sort -rss,-cpu"
    process_list = subprocess.check_output(command, shell=True)
    return process_list

def load_whitelist(fname):
    white_list = ""
    return white_list

def list_process(process_list, white_list):
    output =""
    return output

################################################################################
if __name__=='__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--whitelist_file', required=False,
                        help="config file for whitelist", type=str)
    args = parser.parse_args()

    nonkernel_process_list = get_nonkernel_process()
    white_list = load_whitelist(args.whitelist_file)
    process_list = list_process(nonkernel_process_list, white_list)
    print process_list
## File : detect_suspicious_process.py ends
