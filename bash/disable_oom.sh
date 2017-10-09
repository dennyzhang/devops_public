#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
## https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : disable_oom.sh
## Author : Denny <contact@dennyzhang.com>
## Description :
## Sample:
## --
## Created : <2016-06-04>
## Updated: Time-stamp: <2017-10-09 11:55:37>
##-------------------------------------------------------------------
pid_file=${1?}

LOG_FILE="/var/log/disable_oom.log"

function log() {
    local msg=$*
    date_timestamp=$(date +['%Y-%m-%d %H:%M:%S'])
    echo -ne "$date_timestamp $msg\n"
    
    if [ -n "$LOG_FILE" ]; then
        echo -ne "$date_timestamp $msg\n" >> "$LOG_FILE"
    fi
}

if [ ! -f "$pid_file" ]; then
    log "Error $pid_file doesn't exist"
    exit 1
fi

pid=$(cat "$pid_file")
if [ ! -d "/proc/$pid" ]; then
    log "Warning: process($pid) is not alive"
    exit 0
fi

# http://backdrift.org/oom-killer-how-to-create-oom-exclusions-in-linux
log "disable oom for $pid"
echo -17 > "/proc/$pid/oom_score_adj"
## File : disable_oom.sh ends
