# -*- coding: utf-8 -*-
#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT 
##   https://www.dennyzhang.com/wp-content/mit_license.txt
##
## File : cloud_cost_slack_report.py
## Author : Denny <contact@dennyzhang.com>
## Description :
## --
## Created : <2017-01-01>
## Updated: Time-stamp: <2017-09-07 21:36:07>
##-------------------------------------------------------------------
import os, sys, json
import requests
import subprocess

def quit_if_empty(string, err_msg):
    if string is None or string == '':
        print("Error: string is null or empty. %s" % (err_msg))
        sys.exit(-1)

################################################################################
def linode_get_price(cloud_token):
    url = "https://api.linode.com/?api_key=%s&api_action=avail.linodeplans" % (cloud_token)
    price_dict = {}
    r = requests.get(url)
    if r.status_code != 200:
        print("Error to call rest api. response: %s" % (r.text))
        sys.exit(1)
    response_json = r.json()
    for d in response_json['DATA']:
        price_dict[str(d['PLANID'])] = d['PRICE']
    return price_dict

def linode_get_ip(cloud_token):
    url = "https://api.linode.com/?api_key=%s&api_action=linode.ip.list" % (cloud_token)
    ip_dict = {}
    r = requests.get(url)
    if r.status_code != 200:
        print("Error to call rest api. response: %s" % (r.text))
        sys.exit(1)
    response_json = r.json()
    for d in response_json['DATA']:
        ip_dict[str(d['LINODEID'])] = d['IPADDRESS']
    return ip_dict

def linode_list_vm(cloud_token):
    price_map = linode_get_price(cloud_token)
    ip_map = linode_get_ip(cloud_token)
    url = "https://api.linode.com/?api_key=%s&api_action=linode.list" % (cloud_token)
    r = requests.get(url)
    if r.status_code != 200:
        print("Error to call rest api. response: %s" % (r.text))
        sys.exit(1)
    response_json = r.json()
    vm_list = []
    tmp_list = []
    total_price = 0
    for d in response_json['DATA']:
        total_price += float(price_map[str(d["PLANID"])])
        tmp_list.append([str(d["LINODEID"]), d["LABEL"], \
                              ip_map[str(d["LINODEID"])], str(price_map[str(d["PLANID"])])])
    # sort by label
    tmp_list = sorted(tmp_list, key=lambda x: x[1])
    # generate output
    vm_list.append("Estimated total monthly cost: %s" % (str(total_price)))
    vm_list.append("{0:16} {1:25} {2:20} {3:10}".\
                   format('LINODEID', 'LABEL', 'IPADDRESS', 'Price'))

    for d in tmp_list:
        vm_list.append("{0:16} {1:25} {2:20} {3:10}".\
                       format(d[0], d[1], d[2], d[3]))
    return vm_list
################################################################################

def digitalocean_list_vm(cloud_token):
    max_droplets_count = '500' # max fetched vm count
    url = 'https://api.digitalocean.com/v2/droplets?page=1&per_page=%s' \
                                                          % (max_droplets_count)
    headers = {'Content-Type': 'application/json', \
               'Authorization': "Bearer %s" % (cloud_token)}
    r = requests.get(url, headers = headers)
    if r.status_code != 200:
        print("Error to call rest api. response: %s" % (r.text))
        sys.exit(1)
    response_json = r.json()
    vm_list = []
    tmp_list = []
    total_price = 0
    for d in response_json['droplets']:
        total_price += float(d["size"]["price_monthly"])
        tmp_list.append([str(d["id"]), d["name"], d["networks"]["v4"][0]["ip_address"], \
                         str(d["size"]["price_monthly"])])
    # sort by hostname
    tmp_list = sorted(tmp_list, key=lambda x: x[1])
    # generate output
    vm_list.append("Estimated total monthly cost: %s" % (str(total_price)))
    vm_list.append("{0:16} {1:20} {2:20} {3:10}".\
                   format('ID', 'Name', 'IP', 'Price'))

    for d in tmp_list:
        vm_list.append("{0:16} {1:20} {2:20} {3:10}".\
                       format(d[0], d[1], d[2], d[3]))
    return vm_list

def generate_slack_message(vm_list, cloud_type, \
                           slack_channel, slack_token):
    tmp_fname = "/tmp/%s_Cost_For_All_VMs.txt" % (cloud_type)
    initial_comment = "Cost Breakdown For All Running VMs of %s" % (cloud_type)

    print("Generate slack message to %s" % (slack_channel))

    # generate file
    f = open(tmp_fname,'wab')
    for row in vm_list:
        f.write(row)
        f.write("\n")
    f.close()

    curl_command = "curl -F \"file=@%s\" -F initial_comment=\"Cost Breakdown For All Running VMs of %s\" -F channels=\"#%s\" -F token=\"%s\" https://slack.com/api/files.upload" \
                                    % (tmp_fname, cloud_type, slack_channel, slack_token)
    print(curl_command)
    # TODO: trap errors of curl failure
    p = subprocess.Popen(curl_command, shell = True, stderr = subprocess.PIPE)
    while True:
        out = p.stderr.read(1)
        if out == '' and p.poll() != None:
            break
        if out != '':
            sys.stdout.write(out)
            sys.stdout.flush()

    # remove tmpfile
    os.remove(tmp_fname)

'''
# Test Digitalocean
export CLOUD_TOKEN='XXX'
export CLOUD_TYPE='DIGITALOCEAN'
export SLACK_CHANNEL='XXX'
export SLACK_TOKEN='XXX'

python ./cloud_cost_slack_report.py

# Test Linode
export CLOUD_TYPE='LINODE'
export CLOUD_TOKEN='XXX'
export SLACK_CHANNEL='XXX'
export SLACK_TOKEN='XXX'

python ./cloud_cost_slack_report.py
'''

if __name__ == '__main__':
    cloud_token = os.environ.get('CLOUD_TOKEN')
    cloud_type = os.environ.get('CLOUD_TYPE')
    slack_token = os.environ.get('SLACK_TOKEN')
    slack_channel = os.environ.get('SLACK_CHANNEL')

    # Input parameters check
    quit_if_empty(cloud_token, "CLOUD_TOKEN must be given.")
    quit_if_empty(cloud_type, "CLOUD_TYPE must be given.")
    quit_if_empty(slack_token, "SLACK_TOKEN must be given.")
    quit_if_empty(slack_channel, "SLACK_CHANNEL must be given.")

    vm_list = []
    print("Call rest api to list vms")
    if cloud_type == 'DIGITALOCEAN':
        vm_list = digitalocean_list_vm(cloud_token)
    elif cloud_type == 'LINODE':
        vm_list = linode_list_vm(cloud_token)
    else:
        print("Error: unsupported cloud type: %s" % (cloud_type))
        sys.exit(1)

    generate_slack_message(vm_list, cloud_type, \
                           slack_channel, slack_token)
## File : cloud_cost_slack_report.py ends
