#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2015 DennyZhang.com
## File : detect_suspicious_process.py
## Author : DennyZhang.com <contact@dennyzhang.com>
## Description : https://www.dennyzhang.com/suspicious_process
##        python ./detect_suspicious_process.py
##        python ./detect_suspicious_process.py --whitelist_file /tmp/whitelist.txt
##
## More reading: https://www.dennyzhang.com/suspicious_process
##
## --
## Created : <2016-01-15>
## Updated: Time-stamp: <2017-09-04 18:55:31>
##-------------------------------------------------------------------
import argparse
import subprocess
import os, sys

################################################################################
# TODO: move to common library
def string_in_regex_list(string, regex_list):
    import re
    for regex in regex_list:
        regex = regex.strip()
        if regex == "":
            continue
        if re.search(regex, string) is not None:
            return True
    return False

################################################################################
DEFAULT_WHITE_LIST = '''
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

COMMAND_GET_NONKERNEL = '''
sudo ps --ppid 2 -p 2 -p 1 --deselect \
-o uid,pid,rss,%cpu,command \
--sort -rss,-cpu
'''

def get_nonkernel_process():
    process_list = subprocess.check_output(COMMAND_GET_NONKERNEL, shell=True)
    return process_list

def load_whitelist(fname):
    white_list = ""
    if fname is None:
        print("No white list file is given. Use default value.")
        white_list = DEFAULT_WHITE_LIST
    else:
        print("load white list from %s" % (fname))
        with open(fname) as f:
            white_list = f.readlines()
    return white_list

def list_process(process_list, white_list):
    import re
    l = []
    for line in process_list.split("\n"):
        line = line.strip()
        if line == "":
            continue
        if not string_in_regex_list(line, white_list.split("\n")):
            l.append(line)
    return l

################################################################################
if __name__=='__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--whitelist_file', required=False,
                        help="config file for whitelist", type=str)
    args = parser.parse_args()
    white_list = load_whitelist(args.whitelist_file)
    nonkernel_process_list = get_nonkernel_process()
    process_list = list_process(nonkernel_process_list, white_list)

    # Remove header
    print("Identified processes count: %d." % (len(process_list) - 1))
    print("\n".join(process_list))
## File : detect_suspicious_process.py ends
