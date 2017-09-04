#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
## https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : format_hdfs.sh
## Author : Denny <contact@dennyzhang.com>
## Description :
## --
## Created : <2016-06-04>
## Updated: Time-stamp: <2017-09-04 18:54:41>
##-------------------------------------------------------------------
flagfile=${1?}

if [ -f "$flagfile" ]; then
    log "Error: $flagfile exists, which indicates it's already initialized"
    exit 1
fi

su -s /bin/bash hdfs -c "hdfs namenode -format"

touch "$flagfile"
## File : format_hdfs.sh ends
