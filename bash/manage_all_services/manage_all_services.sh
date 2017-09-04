#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
## https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : manage_all_services.sh
## Author : Denny <contact@dennyzhang.com>
## Description :
#         Sample:
#          manage_all_services.sh start couchbase-server,elasticsearch
#          manage_all_services.sh stop elasticsearch
#          manage_all_services.sh status couchbase-server
## --
## Created : <2016-06-04>
## Updated: Time-stamp: <2017-09-04 18:54:43>
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
    action=${1?}
    service_list=${2?}

    fail_unless_root

    log "========= $action $service_list ============"
    IFS=$','
    for service in $service_list; do
        unset IFS
        if [ -f "/etc/init.d/$service" ]; then
            command="service $service $action"
            log "$command"
            eval "$command"
        fi
    done
    log "Action Pass"
}

function shell_exit {
    if [ $? -ne 0 ]; then
        log "Error: Action Failed"
        exit 1
    fi
}

################################################################################
trap shell_exit SIGHUP SIGINT SIGTERM 0
action=${1?}
service_list=${2?}

manage_service "$action" "$service_list"
## File: manage_all_services.sh ends
