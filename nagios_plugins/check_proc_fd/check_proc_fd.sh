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

function print_help {
    echo "check_proc_fd v1.0"
    echo ""
    echo "Usage:"
    echo "check_proc_fd.sh -w <warn_FD> -c <criti_FD> <pid_pattern> <pattern_argument>"
    echo ""
    echo "Below: If tomcat open more than 1024 file handler, send warning"
    echo "check_proc_fd.sh -w 1024 -c 2048 --pidfile /var/run/tomcat7.pid"
    echo "check_proc_fd.sh -w 1024 -c 2048 --pid 11325"
    echo "check_proc_fd.sh -w 1024 -c 2048 --cmdpattern \"tomcat7.*java.*MaxPermSize\""
    echo ""
    echo "Copyright (C) 2014 DennyZhang (contact@dennyzhang.com)"
}

while [ "$#" -gt 0 ]
do
    opt=$1
    case $opt in
        -w)
            warn_fd=$2
            shift 2 # Past argument and value
        ;;
        -c)
            criti_fd=$2
            shift 2 # Past argument and value
        ;;
        --pidfile)
            pidfile=$2
            pid=$(cat "$pidfile")
            shift 2 # Past argument and value
        ;;
        --cmdpattern)
            cmdpattern=$2
            pid=$(pgrep -a -f "$cmdpattern" | grep -v `basename $0` | head -n 1 | awk -F' ' '{print $1}')
            shift 2 # Past argument and value
        ;;
        --pid)
            pid=$2
            shift 2 # Past argument and value
        ;;
        *)
            print_help
            exit 3
        ;;
    esac
done

num_re='^[0-9]+$'
if ! [[ "$warn_fd" =~ $num_re ]] || ! [[ "$criti_fd" =~ $num_re ]]
then
    echo "ERROR: Warning or Critical level is not a number"
    exit 3
fi

if [ -z "$pid" ]; then
    echo "ERROR: no related process is found"
    exit 2
fi

# Note: nagios need use sudo to run lsof
fdcount=$(sudo lsof -p "$pid" | wc -l)

if [ "$fdcount" -ge "$criti_fd" ]; then
    echo "CRITICAL: number of files opened by pid($pid) is $fdcount. It's more than $criti_fd|fd=$fdcount"
    exit 2
elif [ "$fdcount" -ge "$warn_fd" ]; then
    echo "WARNING: number of files opened by pid($pid) is $fdcount. It's more than $warn_fd|fd=$fdcount"
    exit 1
else
    echo "OK: number of files opened by pid($pid) is $fdcount|fd=$fdcount"
    exit 0
fi
## File - check_proc_fd.sh ends
