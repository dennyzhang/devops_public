#!/bin/bash -ex
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
## https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : ufw_add_node_to_cluster.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
## --
## Created : <2016-12-26>
## Updated: Time-stamp: <2016-12-26 12:04:34>
##-------------------------------------------------------------------
allow_ip_list=${1?}
allow_tcp_port=${2:-"2702 22"}

iptables-save > "/root/$(date +'%Y%m%d_%H%M%S')_rules.v4"
iptables -F; iptables -X
echo 'y' | ufw reset
echo 'y' | ufw enable
ufw default deny incoming
ufw default deny forward
for port in $allow_tcp_port; do
    ufw allow "$port/tcp"
done

for ip in $allow_ip_list; do
    ufw allow from "$ip"
done
## File : ufw_add_node_to_cluster.sh ends
