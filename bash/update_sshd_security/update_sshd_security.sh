#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : update_sshd_security.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
## --
## Created : <2015-05-13>
## Updated: Time-stamp: <2017-06-09 14:20:31>
##-------------------------------------------------------------------
function log() {
    local msg=$*
    date_timestamp=$(date +['%Y-%m-%d %H:%M:%S'])
    echo -ne "$date_timestamp $msg\n"

    if [ -n "$LOG_FILE" ]; then
        echo -ne "$date_timestamp $msg\n" >> "$LOG_FILE"
    fi
}

LOG_FILE="/var/log/update_sshd_security.log"

ssh_port=${1:-"2702"}
root_pwd=${2:-""}

################################################################################
# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root." 1>&2
    exit 1
fi
## File : update_sshd_security.sh ends
