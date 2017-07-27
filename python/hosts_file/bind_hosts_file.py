#!/usr/bin/python
## File : bind_hosts_file.py
## Created : <2017-05-03>
## Updated: Time-stamp: <2017-07-26 19:00:38>
## Description :
##    Configure /etc/hosts for a list of nodes.
##    1. Given a list of ip.
##    2. Get the ip-hostname list for each node by ssh
##    3. Update /etc/hosts for each node, thus every node to talk with others by hostname
## Sample:
##    python ./bind_hosts_file.py --ip_list_file /tmp/hosts --ssh_username root
##                \ --ssh_port 22 --ssh_key_file ~/.ssh/id_rsa
## Requirements:
##     1. pip install paramiko
##     2. Python version: Python2, instead of Python3
##     3. In each node: wget -O /usr/sbin/update_hosts_file.py https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v6/python/hosts_file/update_hosts_file.py
##-------------------------------------------------------------------
import os, sys
import paramiko
import argparse

# multiple threading for a list of ssh servers
import Queue
import threading

import logging
log_folder = "%s/log" % (os.path.expanduser('~'))
if os.path.exists(log_folder) is False:
    os.makedirs(log_folder)
log_file = "%s/%s.log" % (log_folder, os.path.basename(__file__).rstrip('\.py'))

logging.basicConfig(filename=log_file, level=logging.DEBUG, format='%(asctime)s %(message)s')
logging.getLogger().addHandler(logging.StreamHandler())

def get_list_from_file(fname):
    l = []
    with open(fname,'r') as f:
        for row in f:
            row = row.strip()
            if row.startswith('#') or row == '':
                continue
            l.append(row)
    return l

def get_hostname_by_ssh(server_ip, username, ssh_port, ssh_key_file, key_passphrase):
    ssh_command = "hostname"
    output = ""
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        key = paramiko.RSAKey.from_private_key_file(ssh_key_file, password=key_passphrase)
        ssh.connect(server_ip, username=username, port=ssh_port, pkey=key)
        stdin, stdout, stderr = ssh.exec_command(ssh_command)
        output = "\n".join(stdout.readlines())
        output = output.rstrip("\n")
    except:
        return ("ERROR", "Unexpected on server: %s error: %s" % (server_ip, sys.exc_info()[0]))
    return ("OK", output)

def get_hostname_ip_dict(server_list, ssh_username, ssh_port, ssh_key_file, key_passphrase):
    binding_dict = {}
    # TODO: speed up this process by multi-threading
    for server_ip in server_list:
        (status, hostname) = get_hostname_by_ssh(server_ip, ssh_username, ssh_port, ssh_key_file, key_passphrase)
        binding_dict[server_ip] = hostname
    return binding_dict

def bind_hosts_file(server_list, hostname_ip_dict, ssh_username, ssh_port, ssh_key_file, key_passphrase):
    ip_hostname_list = []
    for hostname in hostname_ip_dict:
        ip_hostname_list.append("%s %s" % (hosntame, hostname_ip_dict[hostname]))

    # TODO: speed up this process by multi-threading
    ssh_command = "cat > /tmp/hosts << EOF
%s
EOF && \
python update_hosts_file.py --extra_hosts_file /tmp/hosts" % ("\n".join(ip_hostname_list))
    for server_ip in server_list:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        key = paramiko.RSAKey.from_private_key_file(ssh_key_file, password=key_passphrase)
        ssh.connect(server_ip, username=username, port=ssh_port, pkey=key)
        stdin, stdout, stderr = ssh.exec_command(ssh_command)
        output = "\n".join(stdout.readlines())
        output = output.rstrip("\n")
        # TODO: verify status

###############################################################

if __name__ == '__main__':
    # get parameters from users
    parser = argparse.ArgumentParser()
    parser.add_argument('--ip_list_file', required=True, default="", \
                        help="File for a list of ip address", type=str)
    parser.add_argument('--ssh_username', required=False, default="root", \
                        help="Which OS user to ssh", type=str)
    parser.add_argument('--ssh_port', required=False, default="22", \
                        help="Which port to connect sshd", type=int)
    parser.add_argument('--ssh_key_file', required=False, default="%s/.ssh/id_rsa" % os.path.expanduser('~'), \
                        help="ssh key file to connect", type=str)
    parser.add_argument('--key_passphrase', required=False, default="", \
                        help="Which OS user to ssh", type=str)

    l = parser.parse_args()
    # TODO: improve error handling
    server_list = get_list_from_file(l.ip_list_file)
    binding_dict = get_hostname_ip_dict(server_list, l.ssh_username, l.ssh_port, l.ssh_key_file, l.key_passphrase)
    bind_hosts_file(server_list, binding_dict, l.ssh_username, l.ssh_port, l.ssh_key_file, l.key_passphrase)
    # TODO: check status
## File : bind_hosts_file.py ends
