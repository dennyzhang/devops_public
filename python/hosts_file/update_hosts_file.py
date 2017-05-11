# -*- coding: utf-8 -*-
#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2017 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : update_hosts_file.py
## Author : Denny <denny@dennyzhang.com>
## Created : <2017-05-03>
## Updated: Time-stamp: <2017-05-11 11:34:50>
## Description :
##    Load an extra hosts binding into /etc/hosts
## Sample:
##        python ./examine_hosts_file.py --extra_hosts_file /tmp/hosts
##-------------------------------------------------------------------
import os, sys
import argparse

import logging
log_file = "/var/log/%s.log" % (os.path.basename(__file__).rstrip('\.py'))

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

    l = parser.parse_args()
    extra_hosts_file = l.extra_hosts_file

    current_hosts_dict = load_hostsfile_to_dict("/etc/hosts")
    extra_hosts_dict = load_hostsfile_to_dict(extra_hosts_file)
    has_changed = False
    for hostname in extra_hosts_dict:
        if hostname not in current_hosts_dict:
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
