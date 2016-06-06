#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : status_all.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
## --
## Created : <2016-06-04>
## Updated: Time-stamp: <2016-06-06 12:22:51>
##-------------------------------------------------------------------
. /etc/profile

if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root." 1>&2
    exit 1
fi

function clean_up {
    if [ $? -ne 0 ]; then
        echo "Error to run $0"
        exit 1
    fi
}

trap clean_up SIGHUP SIGINT SIGTERM 0
echo "========= Stop services ============"

service_list="couchbase-server,elasticsearch,mdm"

IFS=$','
for service in $service_list; do
    unset IFS
    if [ -f "/etc/init.d/$service" ]; then
        service $service status
    fi
done
## File: status_all.sh ends
