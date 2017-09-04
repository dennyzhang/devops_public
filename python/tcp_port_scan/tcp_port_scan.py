#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2015 DennyZhang.com
## File : tcp_port_scan.py
## Author : DennyZhang.com <contact@dennyzhang.com>
## Description :
## More reading: https://www.dennyzhang.com/nmap_port_scan
## --
## Created : <2016-01-15>
## Updated: Time-stamp: <2017-09-04 18:55:30>
##-------------------------------------------------------------------
import argparse
import subprocess
import os, sys

################################################################################
# TODO: move to common library
def strip_remove_comments(string):
    # remove empty lines and comments (# ...) from string
    l = []
    for line in string.split("\n"):
        line = line.strip()
        if line.startswith("#") or line == "":
            continue
        l.append(line)
    return "\n".join(l)

def strip_remove_emptylines(string):
    l = []
    for line in string.split("\n"):
        line = line.strip()
        if line == "":
            continue
        l.append(line)
    return "\n".join(l)

def string_remove_patterns(string, opt_list):
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

def string_remove_extra_whitespace(string):
    import re
    return re.sub(' +',' ', string).strip()

def load_paralist_from_file(fname):
    # TODO: defensive coding when file doesn't exist
    l = []
    with open(fname,'r') as f:
        for line in f:
            line = line.strip()
            if not line.startswith("#") and line != "":
                l.append(line)
    return l

# TODO: add common logging
################################################################################
nmap_command = "sudo nmap -sS -PN %s" # ("-p T:XXX,XXX 192.168.0.16")
output_prefix = "============="
open_port_dict = {}
insecure_port_dict = {}

# TODO: make sure nmap has been installed in current machine
def nmap_check(server_ip, ports):
    if ports == "":
        nmap_opts = server_ip
    else:
        nmap_opts = "-p %s %s" % (ports, server_ip)
    command = nmap_command % (nmap_opts)
    print(output_prefix, "Run: %s" % (command))
    nmap_output = subprocess.check_output(command, shell=True)
    print(nmap_output)
    return nmap_output

def get_portlist_by_nmap_output(nmap_output):
    opt_list = ["Starting Nmap ", "Nmap scan report for ", "Host is ", \
                "Not shown: ", " STATE ", " closed ", \
                " filtered ", "Nmap done: ", " scanned ports on ", \
                "MAC Address: "]
    output = string_remove_extra_whitespace(nmap_output)
    output = string_remove_patterns(output, opt_list)
    output = strip_remove_emptylines(output)
    if output == "":
        return []
    else:
        return output.split("\n")

def audit_open_ports(port_list, white_list, server_ip):
    insecure_port_list = []
    for item in port_list:
        port = item.split("/")[0]

        if "*:%s" % (port) not in white_list and \
           "%s:%s" % (server_ip, port) not in white_list:
            insecure_port_list.append(item)

    return insecure_port_list

def tcp_port_scan(server_list, white_list, extra_port_list):
    # TODO: change to multi-threading
    for server_ip in server_list:
        nmap_output = nmap_check(server_ip, "")
        nmap_port_list = get_portlist_by_nmap_output(nmap_output)
        open_port_dict[server_ip] = nmap_port_list

    # TODO: change to multi-threading
    extra_ports = ",".join(extra_port_list)
    if extra_ports != "":
        print("%s Run extra checks for given ports: %s" % (output_prefix, extra_ports))
        for server_ip in server_list:
            nmap_output = nmap_check(server_ip, "T:%s" % (extra_ports))
            nmap_port_list = get_portlist_by_nmap_output(nmap_output)
            open_port_dict[server_ip] = sorted(list(set(open_port_dict[server_ip]) \
                                                    | set(nmap_port_list)))

    # reduce result: whether any insecure ports open
    detected_insecure_ports = False
    for server_ip in server_list:
        ports = audit_open_ports(open_port_dict[server_ip], white_list, server_ip)
        if len(ports) != 0:
            detected_insecure_ports = True
            insecure_port_dict[server_ip] = ports

    if detected_insecure_ports is True:
        print(output_prefix, "Error: Detected Insecure TCP Ports Open")
        for server_ip in insecure_port_dict.keys():
            print("\nServer: %s" % (server_ip))
            print("\n".join(insecure_port_dict[server_ip]))
        sys.exit(1)
    else:
        print("OK: No Insecure TCP Ports Open")

################################################################################
if __name__=='__main__':
    # Sample:
    # python ./tcp_port_scan.py --server_list_file /tmp/server_list --white_list_file /tmp/white_list --extra_port_list_file /tmp/extra_port_list
    parser = argparse.ArgumentParser()
    parser.add_argument('--server_list_file', required=True,
                        help="ip list to scan", type=str)
    parser.add_argument('--white_list_file', required=True,
                        help="safe ports to allow open", type=str)
    parser.add_argument('--extra_port_list_file', required=True,
                        help="customized tcp ports to scan", type=str)
    args = parser.parse_args()

    white_list = load_paralist_from_file(args.white_list_file)
    server_list = load_paralist_from_file(args.server_list_file)
    extra_port_list = load_paralist_from_file(args.extra_port_list_file)

    tcp_port_scan(server_list, white_list, extra_port_list)
## File : tcp_port_scan.py ends
