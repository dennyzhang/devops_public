#!/bin/bash -e
##-------------------------------------------------------------------
## File : enable_ufw.sh
## Author : Denny <contact@dennyzhang.com>
## Description :
## --
## Created : <2015-05-12>
## Updated: Time-stamp: <2017-09-04 18:54:43>
##-------------------------------------------------------------------
# Check OS version
function log() {
    local msg=$*
    date_timestamp=$(date +['%Y-%m-%d %H:%M:%S'])
    echo -ne "$date_timestamp $msg\n"

    if [ -n "$LOG_FILE" ]; then
        echo -ne "$date_timestamp $msg\n" >> "$LOG_FILE"
    fi
}

LOG_FILE="/var/log/enable_ufw.log"

function default_ufw_setting() {
    local whether_reset_rules=${1?}

    if [ "$whether_reset_rules" = "yes" ]; then
        log "reset ufw rules"
        echo 'y' | ufw reset
    fi

    echo 'y' | ufw enable

    log "set up default policy to deny"
    ufw default deny incoming
    ufw default deny forward
}

function ufw_allow_ports() {
    local port_list=${1?}
    for port in ${port_list//,/ }; do
        log "ufw allow $port/tcp"
        ufw allow "$port"/tcp
    done
}

function ufw_allow_nic() {
    local nic_list=${1?}
    for nic in ${nic_list//,/ }; do
        log "ufw allow in on $nic"
        ufw allow in on "$nic"
    done
}

# Sample: ./enable_ufw.sh "yes" "22,443,80,18080" "docker0,eth0"

whether_reset_rules=${1?"Whether to reset ufw rules(YES or NO)"} 
open_tcp_ports=${2?"Port list to open"}
open_nic_list=${3?"Network nics to open"}

default_ufw_setting "$whether_reset_rules"
ufw_allow_ports "$open_tcp_ports"
ufw_allow_nic "$open_nic_list"
## File : enable_ufw.sh ends
