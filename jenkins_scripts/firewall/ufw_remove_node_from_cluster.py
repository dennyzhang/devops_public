# -*- coding: utf-8 -*-
#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
## https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : ufw_remove_node_from_cluster.py
## Author : Denny <denny@dennyzhang.com>
## Description :
## Here we assume firewall should allow all traffic within the Intranet.
## Running a cluster of nodes in certain public cloud,
## like Linode, we don't have private subnet.
## Thus to remove an existing one node, we need:
## Go to all existing nodes, and remove firewall rules related to current node
## --
## Created : <2016-12-13>
## Updated: Time-stamp: <2016-12-13 22:43:37>
##-------------------------------------------------------------------
def test():
    print "hello, world"

if __name__ == '__main__':
    test()

## File : ufw_remove_node_from_cluster.py ends
