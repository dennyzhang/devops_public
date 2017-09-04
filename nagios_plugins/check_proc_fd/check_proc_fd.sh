#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File: check_proc_fd.sh
## Author : Denny <contact@dennyzhang.com>
## Description :
## --
##
## Link: http://https://github.com/DennyZhang/check_proc_fd
##
## Created : <2014-12-17>
## Updated: Time-stamp: <2017-09-04 18:54:36>
##-------------------------------------------------------------------
if [ "$1" = "-w" ] && [ "$2" -gt "0" ] && \
    [ "$3" = "-c" ] && [ "$4" -gt "0" ]; then
    pidPattern=${5?"specify how to get pid"}

    if [ "$pidPattern" = "--pidfile" ]; then
        pidfile=${6?"pidfile to get pid"}
        pid=$(cat "$pidfile")
    elif [ "$pidPattern" = "--cmdpattern" ]; then
        cmdpattern=${6?"command line pattern to find out pid"}
        pid=$(pgrep -a -f "$cmdpattern" | grep -v check_proc_fd.sh | head -n 1 | awk -F' ' '{print $1}')
    elif [ "$pidPattern" = "--pid" ]; then
        pid=${6?"pid"}
    else
        echo "ERROR input for pidpattern"
        exit 2
    fi

    if [ -z "$pid" ]; then
        echo "ERROR: no related process is found"
        exit 2
    fi

    # Note: nagios need use sudo to run lsof
    fdcount=$(sudo lsof -p "$pid" | wc -l)

    if [ "$fdcount" -ge "$4" ]; then
        echo "CRITICAL: file opened by pid($pid) is $fdcount. It's more than $4|fd=$fdcount"
        exit 2
    elif [ "$fdcount" -ge "$2" ]; then
        echo "WARNING: file opened by pid($pid) is $fdcount. It's more than $2|fd=$fdcount"
        exit 1
    else
        echo "OK: file opened by pid($pid) is $fdcount|fd=$fdcount"
        exit 0
    fi

else
    echo "check_proc_fd v1.0"
    echo ""
    echo "Usage:"
    echo "check_proc_fd.sh -w <warn_MB> -c <criti_MB> <pid_pattern> <pattern_argument>"
    echo ""
    echo "Below: If tomcat open more than 1024 file handler, send warning"
    echo "check_proc_fd.sh -w 1024 -c 2048 --pidfile /var/run/tomcat7.pid"
    echo "check_proc_fd.sh -w 1024 -c 2048 --pid 11325"
    echo "check_proc_fd.sh -w 1024 -c 2048 --cmdpattern \"tomcat7.*java.*MaxPermSize\""
    echo ""
    echo "Copyright (C) 2014 DennyZhang (contact@dennyzhang.com)"
    exit
fi
## File - check_proc_fd.sh ends
