# -*- coding: utf-8 -*-
#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2015 DennyZhang.com
## File : tcp_port_scan.py
## Author : DennyZhang.com <denny@dennyzhang.com>
## Description :
## --
## Created : <2016-01-15>
## Updated: Time-stamp: <2016-08-12 08:29:13>
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

def strip_emptylines(string):
    l = []
    for line in string.split("\n"):
        line = line.strip()
        if line == "":
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

open_port_dict = {}
insecure_port_dict = {}

def nmap_check(server_ip, ports):
    if ports == "":
        nmap_opts = server_ip
    else:
        nmap_opts = "-p %s %s" % (ports, server_ip)

    command = nmap_command % (nmap_opts)
    print "Run: %s" % (command)
    nmap_output =subprocess.check_output(command, shell=True)
    print nmap_output
    return nmap_output

def get_portlist_by_nmap_output(nmap_output, server_ip):
    opt_list = ["Starting Nmap ", "Nmap scan report for ", "Host is ", \
                "Not shown: ", "PORT      STATE SERVICE", "Nmap done: "]
    output = string_remove(nmap_output, opt_list)
    output = strip_emptylines(output)
    return output.split("\n")

def audit_open_ports(port_list, white_list, server_ip):
    insecure_port_list = []
    for item in port_list:
        port = item.split("/")[0]

        if "*:%s" % (port) not in white_list and \
           "%s:%s" % (server_ip, port) not in white_list:
            insecure_port_list.append(item)

    return insecure_port_list

def tcp_port_scan(server_list, port_list, white_list):
    # TODO: change to multi-threading
    for server_ip in server_list:
        nmap_output = nmap_check(server_ip, "")
        nmap_port_list = get_portlist_by_nmap_output(nmap_output, server_ip)
        open_port_dict[server_ip] = nmap_port_list

    # TODO: change to multi-threading
    # Check customized ports
    l = list(map(lambda x: "T:%s" % (x), port_list))
    ports = reduce((lambda x, y: "%s %s" % (x, y)), l)
    if ports != "":
        for server_ip in server_list:
            nmap_output = nmap_check(server_ip, ports)
            nmap_port_list = get_portlist_by_nmap_output(nmap_output, server_ip)
            open_port_dict[server_ip] = sorted(list(set(open_port_dict[server_ip]) \
                                                    | set(nmap_port_list)))

    # reduce result: whether any insecure ports open
    detected_insecure_ports = False
    for server_ip in server_list:
        ports = audit_open_ports(open_port_dict[server_ip], white_list, server_ip)
        if len(ports) != 0:
            detected_insecure_ports = True
            insecure_port_dict[server_ip] = ports

    if detected_insecure_ports is False:
        print "Error: Detected insecure TCP ports open"
        for server_ip in insecure_port_dict.keys():
            print "server: server_ip"
            print insecure_port_dict[server_ip]
        sys.exit(1)
    else:
        print "No insecure TCP ports open"

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

    port_list = ["48080", "18080"]
    white_list = ["*:22", "*:80"]
    server_list = ["104.131.129.100", "104.236.159.226"]

    tcp_port_scan(server_list, port_list, white_list)

## File : tcp_port_scan.py ends
