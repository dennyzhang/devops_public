#!/bin/bash -ex
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
## https://www.dennyzhang.com/wp-content/mit_license.txt
##
## File : ufw_add_node_to_cluster.sh
## Author : Denny <contact@dennyzhang.com>
## Description :
## Sample:
## bash ./ufw_add_node_to_cluster.sh "192.168.1.2,192.168.1.3"
## --
## Created : <2016-12-26>
## Updated: Time-stamp: <2017-09-07 21:35:49>
##-------------------------------------------------------------------
function install_packages() {
    if ! which ufw 1>/dev/null 2>&1; then
        echo "apt-get install -y ufw"
        apt-get install -y ufw
    fi
}

function display_ufw_status() {
    ufw status numbered
}

function update_ufw_rules() {
    allow_ip_list=${1?}
    allow_port_list=${2?}
    iptables-save > "/root/$(date +'%Y%m%d_%H%M%S')_rules.v4"
    iptables -F; iptables -X
    echo 'y' | ufw reset
    echo 'y' | ufw enable
    ufw default deny incoming
    ufw default deny forward
    for port in ${allow_port_list//,/ }; do
        ufw allow "$port/tcp"
    done

    for ip in ${allow_ip_list//,/ }; do
        ufw allow from "$ip"
    done
}
################################################################################
allow_ip_list=${1?}
allow_port_list=${2:-"2702,22"}

install_packages
update_ufw_rules "$allow_ip_list" "$allow_port_list"
display_ufw_status
## File : ufw_add_node_to_cluster.sh ends
