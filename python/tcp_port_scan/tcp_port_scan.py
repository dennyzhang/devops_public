# -*- coding: utf-8 -*-
#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2015 DennyZhang.com
## File : tcp_port_scan.py
## Author : DennyZhang.com <denny@dennyzhang.com>
## Description :
## --
## Created : <2016-01-15>
## Updated: Time-stamp: <2016-08-11 23:24:13>
##-------------------------------------------------------------------
import argparse
import subprocess
import os, sys

################################################################################
# TODO: move to common library
def strip_comments(string):
    # remove empty lines and comments (# ...) from string
    l = []
    for line in string.split("\n"):
        line = line.strip()
        if line.startswith("#") or line == "":
            continue
        l.append(line)
    return "\n".join(l)

def string_remove(string, opt_list):
    l = []
    # remove entries from string
    for line in string.split("\n"):
        should_remove = False
        for item in opt_list:
            if item in line:
                should_remove = True
        if should_remove is False:
            l.append(line)
    return "\n".join(l)

# TODO: common logging
################################################################################
nmap_command = "sudo nmap -sS -PN %s" # ("-p T:XXX,XXX 192.168.0.16")

result_dict = {}

def nmap_check(server_ip, ports):
    if ports == "":
        nmap_opts = server_ip
    else:
        nmap_opts = "-p %s %s" % (ports, server_ip)

    command = nmap_command % (nmap_opts)
    print "Run: %s" % (command)
    nmap_output = subprocess.check_output(command, shell=True)
    return cleanup_nmap_output(nmap_output, server_ip)

def cleanup_nmap_output(nmap_output, server_ip):
    return nmap_output

def audit_open_ports(port_list, whitelist):
    return

################################################################################
if __name__=='__main__':
    # Sample:
    # python ./tcp_port_scan.py --server_list_file XXX --port_list_file XXXX --white_list_file XXX
    parser = argparse.ArgumentParser()
    parser.add_argument('--server_list_file', required=True,
                        help="ip list to scan", type=str)
    parser.add_argument('--port_list_file', required=True,
                        help="customized tcp ports to scan", type=str)
    parser.add_argument('--white_list_file', required=True,
                        help="safe ports to allow open", type=str)
    args = parser.parse_args()
    server_list_file = args.server_list_file
    port_list_file = args.port_list_file
    white_list_file = args.white_list_file

    print nmap_check("192.168.0.104", "")
## File : tcp_port_scan.py ends
