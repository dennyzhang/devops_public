#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : kitchen_hook_list_ip.sh
## Author : DennyZhang.com <denny@dennyzhang.com>
## Description : Note the OS user running the script may be root or kitchen!
## --
## Created : <2015-07-03>
## Updated: Time-stamp: <2016-07-04 16:59:52>
##-------------------------------------------------------------------
set +e

# get list of nodes
hosts_list=""
for node in $(kitchen list | grep -v '^Instance' | awk -F' ' '{print $1}'); do
    output=$(kitchen exec "$node" -c "sudo /sbin/ifconfig eth0 | grep 'inet addr:'")
    ip=$(echo "$output" | grep -v LC_ALL | grep -v '^---' | cut -d: -f2 | awk '{print $1}')
    output=$(kitchen exec "$node" -c "sudo hostname")
    hostname=$(echo "$output" | grep -v LC_ALL | grep -v '^---')
    # trim whitespace
    hostname=$(echo "${hostname}" | sed -e 's/^[ \t]*//')
    # TODO: verify ip and hostname are valid
    hosts_list="${hosts_list}\n${ip}:${hostname}"
done

echo -e "Hosts In Current Env:$hosts_list"
## File : kitchen_hook_list_ip.sh ends
