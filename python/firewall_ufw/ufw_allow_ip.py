#!/usr/bin/python
## File : ufw_allow_ip.py
## Created : <2017-05-03>
## Updated: Time-stamp: <2017-08-03 11:34:33>
## Description :
##    Generate ip-host binding list for a list of nodes, when internal DNS is missing.
##    1. For existing nodes, allow traffic from new nodes
##    2. For new nodes, allow traffic from all nodes
##
## Sample:
##    python ./ufw_allow_ip.py --old_ip_list_file /tmp/old_ip_list --new_ip_list_file /tmp/new_ip_list \
##           --ssh_username root --ssh_port 22 --ssh_key_file ~/.ssh/id_rsa
##
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

def get_hostname_by_ssh(server_ip, ssh_connect_args):
    [ssh_username, ssh_port, ssh_key_file, key_passphrase] = ssh_connect_args
    ssh_command = "hostname"
    output = ""
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        key = paramiko.RSAKey.from_private_key_file(ssh_key_file, password=key_passphrase)
        ssh.connect(server_ip, username=ssh_username, port=ssh_port, pkey=key)
        stdin, stdout, stderr = ssh.exec_command(ssh_command)
        output = "\n".join(stdout.readlines())
        output = output.rstrip("\n")
        ssh.close()
    except:
        return ("ERROR", "Unexpected on server: %s error: %s\n" % (server_ip, sys.exc_info()[0]))
    return ("OK", output)

def get_hostname_ip_dict(server_list, ssh_connect_args):
    binding_dict = {}
    # TODO: speed up this process by multi-threading
    for server_ip in server_list:
        (status, output) = get_hostname_by_ssh(server_ip, ssh_connect_args)
        if status != "OK":
            raise Exception("Fail to get hostname for %s: %s" % (server_ip, output))
        binding_dict[server_ip] = output
    return binding_dict

###############################################################

if __name__ == '__main__':
    # get parameters from users
    parser = argparse.ArgumentParser()
    parser.add_argument('--ip_list_file', required=False, default="/tmp/bind_hosts", \
                        help="File for a list of ip address", type=str)
    parser.add_argument('--target_hosts_file', required=False, default="/tmp/hosts", \
                        help="Target host file", type=str)
    parser.add_argument('--ssh_username', required=False, default="root", \
                        help="Which OS user to ssh", type=str)
    parser.add_argument('--ssh_port', required=False, default="22", \
                        help="Which port to connect sshd", type=int)
    parser.add_argument('--ssh_key_file', required=False, default="%s/.ssh/id_rsa" % os.path.expanduser('~'), \
                        help="ssh key file to connect", type=str)
    parser.add_argument('--key_passphrase', required=False, default="", \
                        help="Which OS user to ssh", type=str)

    l = parser.parse_args()
    target_hosts_file = l.target_hosts_file
    server_list = get_list_from_file(l.ip_list_file)
    ssh_connect_args = [l.ssh_username, l.ssh_port, l.ssh_key_file, l.key_passphrase]
    binding_dict = get_hostname_ip_dict(server_list, ssh_connect_args)

    print("Generate extra hosts file to %s" % (target_hosts_file))
    f = open(target_hosts_file, 'w')
    ip_hostname_list = []
    for ip in binding_dict:
        f.write("%s %s\n" % (ip, binding_dict[ip]))
    f.close()
## File : ufw_allow_ip.py ends
