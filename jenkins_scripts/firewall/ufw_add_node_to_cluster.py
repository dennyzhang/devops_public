# -*- coding: utf-8 -*-
#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
## https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : ufw_add_node_to_cluster.py
## Author : Denny <denny@dennyzhang.com>
## Description :
## Here we assume firewall should allow all traffic within the Intranet.
##      Running a cluster of nodes in certain public cloud,
##      like Linode, we don't have private subnet.
##      Thus to add one node, we need:
##          1. Properly configure firewall in the new node
##          2. Change firewall rules in existing node, to allow incoming traffic
## --
## Created : <2016-12-13>
## Updated: Time-stamp: <2016-12-13 22:56:42>
##-------------------------------------------------------------------
import os, sys

################################################################################
## TODO: remove to common library
def check_variable_is_set(val, msg):
    if val is None:
        sys.exit("%s" % (msg))

def remove_comment_in_str(string):
    l = []
    for line in string.split("\n"):
        line = line.strip()
        if line.startswith("#") or line == "":
            continue
        l.append(line)
    return "\n".join(l)

# TODO: better way to manage unit test code
def test_remove_comment_in_str():
    string= '''## server_ip:ssh_port
## couchbase
159.203.247.196:2702

## Elasticsearch
159.203.216.25:2702
107.170.212.76:2702
'''
    print remove_comment_in_str(string)

################################################################################
# How To Test:
# 		export server_ip="127.0.0.1"
# 		export server_list="127.0.0.1"
# 		python ./ufw_add_node_to_cluster.py 
if __name__ == '__main__':
    server_ip_new_node = os.environ.get('server_ip')
    check_variable_is_set(server_ip_new_node, "ERROR: server_ip is not configured")

    server_list_existing = os.environ.get('server_list')
    check_variable_is_set(server_list_existing, "ERROR: server_list is not configured")

    server_list_existing = remove_comment_in_str(server_list_existing)
## File : ufw_add_node_to_cluster.py ends
