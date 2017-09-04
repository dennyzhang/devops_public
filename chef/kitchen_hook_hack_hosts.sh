#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : kitchen_hook_hack_hosts.sh
## Author : DennyZhang.com <contact@dennyzhang.com>
## Description : Note the OS user running the script may be root or kitchen!
## --
## Created : <2015-07-03>
## Updated: Time-stamp: <2017-09-04 18:54:42>
##-------------------------------------------------------------------
set +e

# get list of nodes
hosts_list=""
for node in $(kitchen list | grep -v '^Instance' | grep -v 'WARN' | awk -F' ' '{print $1}'); do
    output=$(kitchen exec "$node" -c "sudo /sbin/ifconfig eth0 | grep 'inet addr:'")
    ip=$(echo "$output" | grep -v 'WARN' | grep -v LC_ALL | grep -v '^---' | cut -d: -f2 | awk '{print $1}')
    output=$(kitchen exec "$node" -c "sudo hostname")
    hostname=$(echo "$output" | grep -v 'WARN' | grep -v LC_ALL | grep -v '^---')
    # trim whitespace
    hostname=$(echo "${hostname}" | sed -e 's/^[ \t]*//')
    # TODO: verify ip and hostname are valid
    hosts_list="${hosts_list},${ip}:${hostname}"
done

echo "hosts_list: $hosts_list"

hosts_arr=(${hosts_list//,/ })
# update /etc/hosts
for host in ${hosts_arr[*]}
do
    host_split=(${host//:/ })
    ip=${host_split[0]}
    domain=${host_split[1]}

    for node in $(kitchen list | grep -v '^Instance' | grep -v 'WARN' | awk -F' ' '{print $1}'); do
        kitchen exec "$node" -c "sudo cp -f /etc/hosts /root/hosts"
        if kitchen exec "$node" -c "sudo grep ${domain} /root/hosts" 1>/dev/null 2>&1; then
            command="sudo sed -i \"/${domain}/c\\${ip}    ${domain}\" /root/hosts"
        else
            command="echo \"${ip}    ${domain}\" | sudo tee -a /root/hosts"
        fi

        echo "Run: $command"
        kitchen exec "$node" -c "$command"

        echo "Run: sudo cp -f /root/hosts /etc/hosts"
        kitchen exec "$node" -c "sudo cp -f /root/hosts /etc/hosts"
    done
done
## File : kitchen_hook_hack_hosts.sh ends
