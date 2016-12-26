# -*- coding: utf-8 -*-
#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
## https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : ufw_add_or_remove.py
## Author : Denny <denny@dennyzhang.com>
## Description :
## Here we assume firewall should allow all traffic within the Intranet.
##      Running a cluster of nodes in certain public cloud,
##      like Linode, we don't have private subnet.
##
##      Thus to add one node, we need:
##          1. Properly configure firewall in the new node
##          2. Change firewall rules in existing node, to allow incoming traffic
##
##      Thus to remove an existing one node, we need:
##         Go to all existing nodes, and remove firewall rules related to current node
## --
## Created : <2016-12-13>
## Updated: Time-stamp: <2016-12-26 12:09:01>
##-------------------------------------------------------------------
import os, sys

################################################################################
## TODO: move to common library
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

################################################################################
def generate_ansible_host(string, fname):
    # TODO
    return

def initialize_ufw_status(ssh_ip, ssh_username, ssh_key, ssh_port, allow_ports):
    print "TODO"
    print "Initialize ufw status"
    # ansible all -m script -a "/root/ufw_add_node_to_cluster.sh" -k

def allow_src_ip(ssh_ip, ssh_username, ssh_key, ssh_port, src_ip):
    print "TODO"
    # ansible all -m command -a "ufw allow from 12.145.25.178"

def disallow_src_ip(ssh_ip, ssh_username, ssh_key, ssh_port, src_ip):
    print "TODO"
    # ansible all -m command -a "ufw delete allow from 12.145.25.178"

################################################################################
# How To Test:
# 		export server_ip="192.168.0.5"
# 		export server_list="192.168.0.2 192.168.0.3 192.168.0.4"
# 		python ./ufw_add_or_remove.py add
# 		python ./ufw_add_or_remove.py remove
if __name__ == '__main__':
    server_ip_new_node = os.environ.get('server_ip')
    check_variable_is_set(server_ip_new_node, "ERROR: server_ip is not configured")

    server_list_existing = os.environ.get('server_list')
    check_variable_is_set(server_list_existing, "ERROR: server_list is not configured")

    # TODO:
    action="remove"
    server_list_existing = remove_comment_in_str(server_list_existing)

    # TODO
    ssh_ip = server_ip_new_node
    ssh_username = "root"
    ssh_key = "/var/lib/jenkins/.ssh"
    ssh_port = "2702"
    allow_ports = ["2702", "80", "443"]

    print "Update ufw rules in new server: %s" % (ssh_ip)
    initialize_ufw_status(ssh_ip, ssh_username, ssh_key, ssh_port, allow_ports)
    # TODO: performance improvement: change to a parallel way
    for src_ip_tmp in server_list_existing:
        allow_src_ip(ssh_ip, ssh_username, ssh_key, ssh_port, src_ip_tmp)

    # TODO: performance improvement: change to a parallel way
    for ssh_ip_tmp in server_list_existing:
        print "Update ufw rules in existing servers: %s" % (ssh_ip_tmp)
        allow_src_ip(ssh_ip_tmp, ssh_username, ssh_key, ssh_port, ssh_ip)
## File : ufw_add_or_remove.py ends
