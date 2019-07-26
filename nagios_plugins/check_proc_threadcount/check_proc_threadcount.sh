#!/bin/bash -e
##-------------------------------------------------------------------
## File: check_proc_threadcount.sh
## Author : Denny <contact@dennyzhang.com>
## Description :
## --
##
## Created : <2015-02-25>
## Updated: Time-stamp: <2017-09-04 18:54:36>
##-------------------------------------------------------------------
function print_help {
    echo "check_proc_threadcount v1.0"
    echo ""
    echo "Usage:"
    echo "check_proc_threadcount.sh -w <warn_count> -c <criti_count> <pid_pattern> <pattern_argument>"
    echo ""
    echo "Below: If tomcat starts more than 1024 threads, send warning"
    echo "check_proc_threadcount.sh -w 1024 -c 2048 --pidfile /var/run/tomcat7.pid"
    echo "check_proc_threadcount.sh -w 1024 -c 2048 --pid 11325"
    echo "check_proc_threadcount.sh -w 1024 -c 2048 --cmdpattern \"tomcat7.*java.*MaxPermSize\""
    echo ""
    echo "Copyright (C) 2017 DennyZhang (contact@dennyzhang.com)"
}

while [ "$#" -gt 0 ]
do
    opt=$1
    case $opt in
        -w)
            warn_count=$2
            shift 2 # Past argument and value
        ;;
        -c)
            criti_count=$2
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
if ! [[ "$warn_count" =~ $num_re ]] || ! [[ "$criti_count" =~ $num_re ]]
then
    echo "ERROR: Warning or Critical level is not a number"
    exit 3
fi

if [ -z "$pid" ]; then
    echo "ERROR: no related process is found"
    exit 2
fi

if [ -z "$pid" ]; then
    echo "ERROR: no related process is found"
    exit 2
fi

thread_count=$(sudo ls "/proc/$pid/task" | wc -l)

if [ "$thread_count" -ge "$criti_count" ]; then
    echo "CRITICAL: thread count of pid($pid) is $thread_count. It's more than $criti_count|threadcount=$thread_count"
    exit 2
elif [ "$thread_count" -ge "$warn_count" ]; then
    echo "WARNING: thread count of pid($pid) is $thread_count. It's more than $warn_count|threadcount=$thread_count"
    exit 1
else
    echo "OK: thread count of pid($pid) is $thread_count|threadcount=$thread_count"
    exit 0
fi
## File - check_proc_threadcount.sh ends
