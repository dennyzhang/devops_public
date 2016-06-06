#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
## https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : library_manage_service.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
## --
## Created : <2016-06-04>
## Updated: Time-stamp: <2016-06-06 14:41:49>
##-------------------------------------------------------------------
. /etc/profile

function log() {
    local msg=$*
    date_timestamp=$(date +['%Y-%m-%d %H:%M:%S'])
    echo -ne "$date_timestamp $msg\n"

    if [ -n "$LOG_FILE" ]; then
        echo -ne "$date_timestamp $msg\n" >> "$LOG_FILE"
    fi
}

function fail_unless_root() {
    # Make sure only root can run our script
    if [[ $EUID -ne 0 ]]; then
        echo "Error: This script must be run as root." 1>&2
        exit 1
    fi
}

function manage_service() {
    service_list=${1:-"all"}
    action=${2:-"status"}

    fail_unless_root
    if [ "$service_list" = "all" ]; then
        service_list="couchbase-server,elasticsearch,mdm"
    fi

    log "========= $action services ============"
    IFS=$','
    for service in $service_list; do
        unset IFS
        if [ -f "/etc/init.d/$service" ]; then
            log "$action $service"
            service "$service" "$action"
        fi
    done
    log "========= Action Ends ============"
}

function shell_exit {
    if [ $? -ne 0 ]; then
        echo "Error to run $0"
        exit 1
    fi
}

## File: library_manage_service.sh ends
