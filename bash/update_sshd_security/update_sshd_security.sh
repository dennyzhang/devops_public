#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
## https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : update_sshd_security.sh
## Author : Denny <contact@dennyzhang.com>
## Description :
## --
## Created : <2015-05-13>
## Updated: Time-stamp: <2017-09-04 18:54:42>
##-------------------------------------------------------------------
ssh_port=${1:-"2702"}
root_pwd=${2:-""}

function log() {
    local msg=$*
    date_timestamp=$(date +['%Y-%m-%d %H:%M:%S'])
    echo -ne "$date_timestamp $msg\n"

    if [ -n "$LOG_FILE" ]; then
        echo -ne "$date_timestamp $msg\n" >> "$LOG_FILE"
    fi
}

function reconfigure_sshd_port() {
    local ssh_port=${1?}
    log "Change sshd port to $ssh_port"
    sed -i "s/Port .*$/Port $ssh_port/g" /etc/ssh/sshd_config
    log "Restart sshd to take effect"
    nohup service ssh restart &
}

function disable_passwd_login() {
    log "Disable ssh passwd login: PasswordAuthentication no"
    sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/g' \
        /etc/ssh/sshd_config
    sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/g' \
        /etc/ssh/sshd_config
}

function reset_root_pwd() {
    log "Reset OS root password"
    local root_pwd=${1?}
    echo "root:$root_pwd" | chpasswd
}

LOG_FILE="/var/log/update_sshd_security.log"

################################################################################
# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root." 1>&2
    exit 1
fi

reconfigure_sshd_port "$ssh_port"
disable_passwd_login
if [ -n "$root_pwd" ]; then
    reset_root_pwd "$root_pwd"
fi
## File : update_sshd_security.sh ends
