# -*- coding: utf-8 -*-
#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2017 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : examine_hosts_file.py
## Author : Denny <denny@dennyzhang.com>
## Created : <2017-05-03>
## Updated: Time-stamp: <2017-05-11 13:55:01>
## Description :
##    Examine /etc/hosts:
##        1. Whether expected list of ip-hostname are included in /etc/hosts
##        2. Whether it has duplicates ip-hostname binding
##        3. Whether one hostname binds to multiple ip addresses
## Sample:
##        python ./examine_hosts_file.py
##        python ./examine_hosts_file.py --extra_hosts_file /tmp/hosts
##-------------------------------------------------------------------
import os, sys
import argparse
import socket

import logging
log_file = "/var/log/%s.log" % (os.path.basename(__file__).rstrip('\.py'))

logging.basicConfig(filename=log_file, level=logging.DEBUG, format='%(asctime)s %(message)s')
logging.getLogger().addHandler(logging.StreamHandler())

def load_hostsfile_to_list(host_file):
    l = []
    with open(host_file,'r') as f:
        for row in f:
            row = row.strip()
            if row.startswith('#') or row == '':
                continue
            entry_l = row.split()

            if '::' in entry_l[0]:
                continue

            ip = entry_l[0]

            if len(entry_l) == 2:
                hostname = entry_l[1]
                l.append((hostname, ip))
            else:
                for hostname in entry_l[1:]:
                    l.append((hostname, ip))
    return l

def load_hostsfile_to_dict(host_file):
    host_dict = {}
    with open(host_file,'r') as f:
        for row in f:
            row = row.strip()
            if row.startswith('#') or row == '':
                continue
            entry_l = row.split()

            if '::' in entry_l[0]:
                continue

            ip = entry_l[0]

            if len(entry_l) == 2:
                hostname = entry_l[1]
                host_dict[hostname] = ip
            else:
                for hostname in entry_l[1:]:
                    host_dict[hostname] = ip
    return host_dict

###############################################################

if __name__ == '__main__':
    # get parameters from users
    parser = argparse.ArgumentParser()
    parser.add_argument('--extra_hosts_file', required=False, default="", \
                        help="Make sure extra hosts mapping are already in place for /etc/hosts", type=str)
    parser.add_argument('--allow_check_for_ips', required=False, default="", \
                        help="Skip checks for entries in /etc/hosts filtered by ip. Separated by comma.", type=str)
    # By default: skip check for entries of current hostname
    parser.add_argument('--allow_check_for_hostnames', required=False, default=socket.gethostname(), \
                        help="Skip checks for entries in /etc/hosts filtered by hostname. Separated by comma.", type=str)

    l = parser.parse_args()
    extra_hosts_file = l.extra_hosts_file
    allow_check_for_ips = l.allow_check_for_ips
    allow_check_for_ip_list = map(lambda x: x.strip(), allow_check_for_ips.split(','))

    allow_check_for_hostnames = l.allow_check_for_hostnames
    allow_check_for_hostname_list = map(lambda x: x.strip(), allow_check_for_hostnames.split(','))

    has_duplicate_entries = False
    has_conflict_entries = False
    has_error_with_extra_hosts = False

    host_list = load_hostsfile_to_list("/etc/hosts")
    host_dict = {}

    for (hostname, ip) in host_list:
        if ip in allow_check_for_ip_list or hostname in allow_check_for_hostname_list:
            continue
        if hostname in host_dict:
            # Check any duplicate entries: ip-hostname mapping
            if host_dict[hostname] == ip:
                if ip not in allow_check_for_ip_list or hostname in allow_check_for_hostname_list:
                    logging.error("Error: Detect duplicate ip-hostname mapping: ip(%s), hostname(%s)" % (ip, hostname))
                    has_duplicate_entries = True
            else:
                # Check any entries which has the same hostname with different ip
                logging.error("Error: Detect conflict entries ip-hostname mapping for %s" % (hostname))
                has_conflict_entries = True
        host_dict[hostname] = ip

    if extra_hosts_file != "":
        current_hosts_dict = load_hostsfile_to_dict("/etc/hosts")
        extra_hosts_dict = load_hostsfile_to_dict(extra_hosts_file)
        for hostname in extra_hosts_dict:
            ip = extra_hosts_dict[hostname]
            if ip in allow_check_for_ip_list or hostname in allow_check_for_hostname_list:
                continue
            if hostname not in current_hosts_dict:
                logging.error("ERROR /etc/hosts is missing entries of hostname:ip (%s:%s)" % \
                              (hostname, ip))
                has_error_with_extra_hosts = True
            else:
                if ip != current_hosts_dict[hostname]:
                    logging.error("ERROR /etc/hosts is conflict with %s for entry of hostname(%s)" % \
                                  (extra_hosts_file, hostname))
                    has_error_with_extra_hosts = True

    if has_duplicate_entries is True or has_conflict_entries is True \
       or has_error_with_extra_hosts is True:
        sys.exit(1)
    else:
        logging.info("OK: /etc/hosts is good.")
## File : examine_hosts_file.py ends
