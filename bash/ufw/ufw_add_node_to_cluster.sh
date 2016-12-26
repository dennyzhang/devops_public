#!/bin/bash -ex
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
## https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : ufw_add_node_to_cluster.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
## Sample:
## bash ./ufw_add_node_to_cluster.sh "192.168.1.2,192.168.1.3"
## --
## Created : <2016-12-26>
## Updated: Time-stamp: <2016-12-26 14:00:48>
##-------------------------------------------------------------------
function install_packages() {
    if ! which ufw 1>/dev/null 2>&1; then
        echo "apt-get install -y ufw"
        apt-get install -y ufw
    fi
}

function update_ufw_rules() {
    allow_ip_list=${1?}
    allow_tcp_port=${2?}
    iptables-save > "/root/$(date +'%Y%m%d_%H%M%S')_rules.v4"
    iptables -F; iptables -X
    echo 'y' | ufw reset
    echo 'y' | ufw enable
    ufw default deny incoming
    ufw default deny forward
    for port in ${allow_tcp_port//,/ }; do
        ufw allow "$port/tcp"
    done

    for ip in ${allow_ip_list//,/ }; do
        ufw allow from "$ip"
    done
}

function display_ufw_status() {
    ufw status numbered
}
################################################################################
allow_ip_list=${1?}
allow_tcp_port=${2:-"2702,22"}

install_packages
update_ufw_rules "$allow_ip_list" "$allow_tcp_port"
display_ufw_status
## File : ufw_add_node_to_cluster.sh ends
