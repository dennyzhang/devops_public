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
## Updated: Time-stamp: <2017-05-10 16:26:30>
## Description :
##    Examine /etc/hosts:
##        1. Whether expected list of ip-hostname are included in /etc/hosts
##        2. Whether it has duplicates ip-hostname binding
##        3. Whether one hostname binds to multiple ip addresses
## Sample:
##    #
##-------------------------------------------------------------------
import os, sys
import argparse

import logging
log_file = "/var/log/%s.log" % (os.path.basename(__file__).rstrip('\.py'))

logging.basicConfig(filename=log_file, level=logging.DEBUG, format='%(asctime)s %(message)s')
logging.getLogger().addHandler(logging.StreamHandler())

def load_hosts_to_list():
    l = []
    with open('/etc/hosts','r') as f:
        for row in f:
            row = row.strip()
            if row.startswith('#') or row == '':
                continue
            entry_l = row.split()

            if '::' in entry_l[0]:
                continue

            if len(entry_l) == 2:
                l.append((entry_l[0], entry_l[1]))
            else:
                ip = entry_l[0]
                for hostname in entry_l[1:]:
                    l.append((ip, hostname))
    return l

if __name__ == '__main__':
    # get parameters from users
    parser = argparse.ArgumentParser()
    parser.add_argument('--extra_hosts_file', required=False, \
                        help="Make sure extra hosts mapping are already in place for /etc/hosts", type=str)

    l = parser.parse_args()

    extra_hosts_file = l.extra_hosts_file

    print load_hosts_to_list()
## File : examine_hosts_file.py ends
