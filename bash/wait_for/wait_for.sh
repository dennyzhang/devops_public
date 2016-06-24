#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
## https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : wait_for.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
## Sample:
## --
## Created : <2016-06-04>
## Updated: Time-stamp: <2016-06-24 15:52:58>
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

function wait_for() {
    # wait_for "service apache2 status" 3
    # wait_for "lsof -i tcp:8080" 10
    # wait_for "nc -z -v -w 5 172.17.0.3 8443"
    local check_command=${1?}
    local timeout_seconds=${2?}

    log "Wait for: $check_command"
    for((i=0; i<timeout_seconds; i++)); do
        if eval "$check_command"; then
            log "Action pass"
            exit 0
        fi
        sleep 1
    done

    log "Error: wait for more than $timeout_seconds"
    exit 1
}

################################################################################
check_command=${1:-"true"}
timeout_seconds=${2:-30}

wait_for "$check_command" "$timeout_seconds"
## File: wait_for.sh ends
