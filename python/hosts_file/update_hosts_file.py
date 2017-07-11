#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2017 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : update_hosts_file.py
## Author : Denny <denny@dennyzhang.com>
## Created : <2017-05-03>
## Updated: Time-stamp: <2017-07-11 16:37:35>
## Description :
##    Load an extra hosts binding into /etc/hosts
## Sample:
##        python ./examine_hosts_file.py --extra_hosts_file /tmp/hosts
##-------------------------------------------------------------------
import os, sys
import argparse
import socket, datetime

import logging
log_folder = "%s/log" % (os.path.expanduser('~'))
if os.path.exists(log_folder) is False:
    os.makedirs(log_folder)
log_file = "%s/%s.log" % (log_folder, os.path.basename(__file__).rstrip('\.py'))

logging.basicConfig(filename=log_file, level=logging.DEBUG, format='%(asctime)s %(message)s')
logging.getLogger().addHandler(logging.StreamHandler())

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
                        help="Load extra hosts into /etc/hosts", type=str)
    parser.add_argument('--skip_current_hostname', required=False, dest='skip_current_hostname', \
                        action='store_true', default=False, \
                        help="Skip the binding for current hostname, if it's specified in --extra_hosts_file")

    l = parser.parse_args()
    extra_hosts_file = l.extra_hosts_file
    skip_current_hostname = l.skip_current_hostname

    current_hosts_dict = load_hostsfile_to_dict("/etc/hosts")
    extra_hosts_dict = load_hostsfile_to_dict(extra_hosts_file)
    has_changed = False
    has_backup = False

    current_hostname = socket.gethostname()
    for hostname in extra_hosts_dict:
        if skip_current_hostname is True and hostname == current_hostname:
            continue

        if hostname not in current_hosts_dict:
            if has_backup is False:
                host_backup_file = "/etc/hosts.%s" % \
                                   (datetime.datetime.utcnow().strftime("%Y-%m-%d_%H%M%S"))
                logging.info("Backup /etc/hosts to %s" % (host_backup_file))
                has_backup = True
            open("/etc/hosts", "ab").write("%s %s" % (extra_hosts_dict[hostname]), hostname)
            logging.error("Append /etc/hosts: (%s:%s)" % (hostname, extra_hosts_dict[hostname]))
            has_changed = True
        else:
            if current_hosts_dict[hostname] != extra_hosts_dict[hostname]:
                logging.error("ERROR /etc/hosts is conflict with %s for entry of hostname(%s)" % \
                              (extra_hosts_file, hostname))
                sys.exit(1)

    if has_changed is True:
        logging.info("OK: /etc/hosts is good after some updates.")
    else:
        logging.info("OK: /etc/hosts is gook with no changes.")
## File : update_hosts_file.py ends
