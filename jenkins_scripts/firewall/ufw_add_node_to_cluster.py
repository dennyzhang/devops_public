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
##      Here we assume firewall should allow all traffic within the Intranet.
##		Running a cluster of nodes in certain public cloud,
##		like Linode, we don't have private subnet.
##		Thus to add one node, we need:
##			1. Properly configure firewall in the new node
##			2. Change firewall rules in existing node, to allow incoming traffic
## --
## Created : <2016-12-13>
## Updated: Time-stamp: <2016-12-13 22:48:27>
##-------------------------------------------------------------------
server_ip_new_node = ""
server_list_existing = ""

################################################################################
## TODO: remove to common library
def remove_comment_in_str(string):
    l = []
    for line in string.split("\n"):
        line = line.strip()
        if line.startswith("#") or line == "":
            continue
        l.append(line)
    return "\n".join(l)
################################################################################

def test():
    string= '''## server_ip:ssh_port
## couchbase
159.203.198.129:2702
45.55.1.132:2702
104.236.179.76:2702
159.203.247.196:2702

## Elasticsearch
159.203.216.25:2702
107.170.212.76:2702
192.241.211.99:2702
159.203.219.53:2702
159.203.211.150:2702
159.203.192.146:2702
107.170.237.239:2702
192.241.203.166:2702
198.199.95.111:2702

## APP
159.203.234.164:2702
159.203.202.27:2702
159.203.198.98:2702
162.243.155.164:2702

## LoadBlanacer
159.203.198.171:2702
159.203.202.250:2702

## Nagios
159.203.204.145:2702
'''
    print remove_comment_in_str(string)
    print "hello, world"

if __name__ == '__main__':
    test()
## File : ufw_add_node_to_cluster.py ends
