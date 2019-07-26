#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File: check_proc_mem.sh
## Author : Denny <contact@dennyzhang.com>
## Description :
## --
##
## Link: https://www.dennyzhang.com/nagois_monitor_process_memory
##
## Created : <2014-10-25>
## Updated: Time-stamp: <2017-09-04 18:54:36>
##-------------------------------------------------------------------

function print_help {
    echo "check_proc_mem v1.0"
    echo ""
    echo "Usage:"
    echo "check_proc_mem.sh -w <warn_MB> -c <criti_MB> <pid_pattern> <pattern_argument>"
    echo ""
    echo "Below: If tomcat use more than 1024MB resident memory, send warning"
    echo "check_proc_mem.sh -w 1024 -c 2048 --pidfile /var/run/tomcat7.pid"
    echo "check_proc_mem.sh -w 1024 -c 2048 --pid 11325"
    echo "check_proc_mem.sh -w 1024 -c 2048 --cmdpattern \"tomcat7.*java.*Dcom\""
    echo ""
    echo "Copyright (C) 2014 DennyZhang (contact@dennyzhang.com)"
}

while [ "$#" -gt 0 ]
do
    opt=$1
    case $opt in
        -w)
            warn_mb=$2
            shift 2 # Past argument and value
        ;;
        -c)
            crit_mb=$2
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
if ! [[ "$warn_mb" =~ $num_re ]] || ! [[ "$crit_mb" =~ $num_re ]]
then
    echo "ERROR: Warning or Critical level is not a number"
    exit 3
fi

if [ -z "$pid" ]; then
    echo "ERROR: no related process is found"
    exit 2
fi

memVmSize=$(grep 'VmSize:' "/proc/${pid}/status" | awk -F' ' '{print $2}')
memVmSize=$((memVmSize/1024))

memVmRSS=$(grep 'VmRSS:' "/proc/${pid}/status" | awk -F' ' '{print $2}')
memVmRSS=$((memVmRSS/1024))

if [ "$memVmRSS" -ge "$crit_mb" ]; then
    echo "Memory: CRITICAL RES: $memVmRSS MB - VIRT: $memVmSize MB used!|RES=$((memVmRSS*1024*1024));;;;"
    exit 2
elif [ "$memVmRSS" -ge "$warn_mb" ]; then
    echo "Memory: WARNING RES: $memVmRSS MB - VIRT: $memVmSize MB used!|RES=$((memVmRSS*1024*1024));;;;"
    exit 1
else
    echo "Memory: OK RES: $memVmRSS MB - VIRT: $memVmSize MB!|RES=$((memVmRSS*1024*1024));;;;"
    exit 0
fi

## File - check_proc_mem.sh ends
