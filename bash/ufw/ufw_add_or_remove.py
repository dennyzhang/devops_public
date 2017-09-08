# -*- coding: utf-8 -*-
#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
## https://www.dennyzhang.com/wp-content/mit_license.txt
##
## File : ufw_add_or_remove.py
## Author : Denny <contact@dennyzhang.com>
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
import argparse
import subprocess
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
    with open(fname,'wab') as f:
        for row in string.split("\n"):
            f.write("%s\n" % row)

def initialize_ufw_status(ssh_ip, ssh_username, ssh_key, ssh_port, \
                          allow_ip_list, allow_port_list):
    # Sample: ansible all -m script -a \
        # "/root/ufw_add_node_to_cluster.sh 192.168.0.2,192.168.0.3 2702,80,443"

    # TODO: use a temporary host file
    tmp_host_fname = '/tmp/hosts_initialize'
    generate_ansible_host("\n".join(allow_ip_list), tmp_host_fname)

    command = "ansible all -i %s -m script -a '/root/ufw_add_node_to_cluster.sh' %s %s" % \
              (tmp_host_fname, ",".join(allow_ip_list), ",".join(allow_port_list))
    print("Initialize ufw status, command: %s" % (command))
    # TODO: quit, if the command fails
    p = subprocess.Popen(command, shell=True, stderr=subprocess.PIPE)
    while True:
        out = p.stderr.read(1)
        if out == '' and p.poll() != None:
            break
        if out != '':
            sys.stdout.write(out)
            sys.stdout.flush()
    # TODO: get status and remove file

def allow_src_ip(ssh_ip, ssh_username, ssh_key, ssh_port, src_ip):
    # ansible all -m command -a "ufw allow from 192.168.0.3"
    # TODO: use a temporary host file
    tmp_host_fname = '/tmp/hosts_allow_ip'
    generate_ansible_host(src_ip, tmp_host_fname)

    command = "ansible all -i %s -m command -a 'ufw allow from %s'" \
              % (tmp_host_fname, src_ip)
    print("allow_src_ip. ssh_ip: %s, command: %s" % (ssh_ip, command))
    # TODO: quit, if the command fails
    p = subprocess.Popen(command, shell=True, stderr=subprocess.PIPE)
    while True:
        out = p.stderr.read(1)
        if out == '' and p.poll() != None:
            break
        if out != '':
            sys.stdout.write(out)
            sys.stdout.flush()
    # TODO: get status and remove file

def disallow_src_ip(ssh_ip, ssh_username, ssh_key, ssh_port, src_ip):
    # ansible all -m command -a "ufw delete allow from 192.168.0.3"
    command = "ansible all -m command -a 'ufw delete allow from %s'" % (src_ip)
    print("disallow_src_ip. ssh_ip: %s, command: %s" % (ssh_ip, command))
    # TODO: quit, if the command fails
    p = subprocess.Popen(command, shell=True, stderr=subprocess.PIPE)
    while True:
        out = p.stderr.read(1)
        if out == '' and p.poll() != None:
            break
        if out != '':
            sys.stdout.write(out)
            sys.stdout.flush()
    # TODO: get status and remove file

################################################################################
# How To Test:
# 		export server_ip="192.168.0.5"
# 		export server_list="192.168.0.2 192.168.0.3 192.168.0.4"
# 		python ./ufw_add_or_remove.py --action add
# 		python ./ufw_add_or_remove.py --action remove

# Install dependency packages
# http://docs.ansible.com/ansible/intro_configuration.html
# https://serversforhackers.com/running-ansible-programmatically
#       apt-get install -y python-pip
#       pip install ansible
# ANSIBLE_CONFIG: ~/.ansible.cfg
##################################################
#       [defaults]
#       log_path = /var/log/ansible.log
#       callback_plugins = /path/to/our/ansible/plugins/callback_plugins:~/.ansible/plugins/callback_plugins/:/usr/share/ansible_plugins/callback_plugins
#
#       [ssh_connection]
#       ssh_args = -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o IdentitiesOnly=yes -o ControlMaster=auto -o ControlPersist=60s
#       control_path = ~/.ansible/cp/ansible-ssh-%%h-%%p-%%r
##################################################
if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--action', default='',
                        required=True, help="Supported action: add or remove", type=str)
    l = parser.parse_args()
    if l.action not in ['add', 'remove']:
        print("Error: supported action is either add or remove")
        sys.exit(1)

    script_fname="/root/ufw_add_node_to_cluster.sh"
    # TODO: specify ssh private key file
    ssh_key = "/var/lib/jenkins/.ssh"
    ssh_username = "root"
    ssh_port = "2702"

    server_ip = os.environ.get('server_ip')
    check_variable_is_set(server_ip, "ERROR: server_ip is not configured")

    server_list_existing = os.environ.get('server_list')
    check_variable_is_set(server_list_existing, "ERROR: server_list is not configured")

    server_list_existing = server_list_existing.replace(" ", "\n")
    server_list_existing = remove_comment_in_str(server_list_existing)

    ssh_ip = server_ip

    # TODO: get action from user input
    if l.action == "add":
        allow_port_list = ["2702", "80", "443", "22"]
        print("Update ufw rules in new server: %s" % (ssh_ip))
        initialize_ufw_status(ssh_ip, ssh_username, ssh_key, ssh_port, \
                              server_list_existing.split("\n"), allow_port_list)

        for src_ip_tmp in server_list_existing.split("\n"):
            allow_src_ip(ssh_ip, ssh_username, ssh_key, ssh_port, src_ip_tmp)

        print("Update ufw rules in existing servers")
        # TODO: use ansible python module to spped up the logic
        for ssh_ip_tmp in server_list_existing.split("\n"):
            allow_src_ip(ssh_ip_tmp, ssh_username, ssh_key, ssh_port, ssh_ip)

    if l.action == "remove":
        # TODO: use ansible python module to spped up the logic
        for ssh_ip_tmp in server_list_existing.split("\n"):
            disallow_src_ip(ssh_ip_tmp, ssh_username, ssh_key, ssh_port, ssh_ip)
## File : ufw_add_or_remove.py ends
