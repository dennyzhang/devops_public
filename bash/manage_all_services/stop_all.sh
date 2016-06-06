#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : stop_all.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
## --
## Created : <2016-06-04>
## Updated: Time-stamp: <2016-06-06 12:15:12>
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

version=$mdm_version
if [ -n "$version" ]; then
    echo "=========== Stop services. Version: $version ====================="
else
    echo "========= Stop services ============"
fi

if [ -f /etc/init.d/couchbase-server ]; then
    service couchbase-server stop
fi

if [ -f /etc/init.d/elasticsearch ]; then
    echo -ne " * "
    service elasticsearch stop
fi

if [ -f /etc/init.d/mdm ]; then
    service mdm stop
fi

## File: stop_all.sh ends
