#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
## https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : wait_for.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
#         Sample:
## --
## Created : <2016-06-04>
## Updated: Time-stamp: <2016-06-10 19:45:36>
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

check_command=${1:-"true"}
timeout_seconds=${2:-3}

log "Wait for: $check_command"
for((i=0; i<timeout_seconds; i++)); do
    if eval "$check_command"; then
        exit 0
    fi
    sleep 1
done

log "Warning: wait for more than $timeout_seconds"
exit 1
## File: wait_for.sh ends
