#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
## https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : create_loop_device.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
## Sample:
## --
## Created : <2016-06-04>
## Updated: Time-stamp: <2016-06-24 15:52:59>
##-------------------------------------------------------------------
file_count=${1?}

function log() {
    local msg=$*
    date_timestamp=$(date +['%Y-%m-%d %H:%M:%S'])
    echo -ne "$date_timestamp $msg\n"
    
    if [ -n "$LOG_FILE" ]; then
        echo -ne "$date_timestamp $msg\n" >> "$LOG_FILE"
    fi
}

for((i=0; i< file_count; i++)); do
    if [ ! -b /dev/loop$i ]; then
        log "mknod -m0660 /dev/loop$i b 7 $i"
        mknod -m0660 /dev/loop$i b 7 $i
    fi
done
## File : create_loop_device.sh ends
