#!/usr/bin/python
## File : bind_hosts_file.py
## Created : <2017-05-03>
## Updated: Time-stamp: <2017-07-26 17:52:10>
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
    except:
        return ("ERROR", "Unexpected on server: %s error: %s" % (server_ip, sys.exc_info()[0]))
    return ("OK", output)

def get_hostname_ip_dict(server_list, ssh_username, ssh_port, ssh_key_file, key_passphrase):
    binding_dict = {}
    # TODO:
    server_ip = "127.0.0.1"
    (status, hostname) = get_hostname_by_ssh(server_ip, ssh_username, ssh_port, ssh_key_file, key_passphrase)
    binding_dict[server_ip] = hostname
    return binding_dict

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
    # TODO
    server_list = "127.0.0.1"
    binding_dict = get_hostname_ip_dict(server_list, l.ssh_username, l.ssh_port, l.ssh_key_file, l.key_passphrase)
    print(binding_dict)
## File : bind_hosts_file.py ends
