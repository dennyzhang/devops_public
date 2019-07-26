#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File: check_proc_cpu.sh
## Author : Denny <contact@dennyzhang.com>
## Description :
## --
##
## Link: https://www.dennyzhang.com/nagois_monitor_process_cpu
##
## Created : <2015-02-25>
## Updated: Time-stamp: <2017-09-04 18:54:36>
##-------------------------------------------------------------------

function print_help {
    echo "check_proc_cpu v1.0"
    echo ""
    echo "Usage:"
    echo "check_proc_cpu.sh -w <warn_cpu> -c <criti_cpu> <pid_pattern> <pattern_argument>"
    echo ""
    echo "Below: If tomcat use more than 200% CPU, send warning."
    echo "Note machines may have multiple cpu cores"
    echo "check_proc_cpu.sh -w 200 -c 400 --pidfile /var/run/tomcat7.pid"
    echo "check_proc_cpu.sh -w 200 -c 400 --pid 11325"
    echo "check_proc_cpu.sh -w 200 -c 400 --cmdpattern \"tomcat7.*java.*Dcom\""
    echo ""
    echo "Copyright (C) 2015 DennyZhang (contact@dennyzhang.com)"
}

while [ "$#" -gt 0 ]
do
    opt=$1
    case $opt in
        -w)
            warn_cpu=$2
            shift 2 # Past argument and value
        ;;
        -c)
            criti_cpu=$2
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
if ! [[ "$warn_cpu" =~ $num_re ]] || ! [[ "$criti_cpu" =~ $num_re ]]
then
    echo "ERROR: Warning or Critical level is not a number"
    exit 3
fi

if [ -z "$pid" ]; then
    echo "ERROR: no related process is found"
    exit 2
fi

cpuUsage=$(ps -p "$pid" -o "%cpu" | tail -n 1 | sed -e 's/^[ \t]*//')

if [ "$(echo "$cpuUsage>$criti_cpu" | bc)" = "1" ]; then
    echo "CRITICAL: CPU usage (${cpuUsage}%) of process $pid is higher than ${criti_cpu}%!|CPU=$cpuUsage"
    exit 2
elif [ "$(echo "$cpuUsage>$warn_cpu" | bc)" = "1" ]; then
    echo "WARNING: CPU usage (${cpuUsage}%) of process $pid is higher than ${warn_cpu}%!|CPU=$cpuUsage"
    exit 1
else
    echo "OK: CPU usage of process $pid is ${cpuUsage}%|CPU=$cpuUsage"
    exit 0
fi
## File - check_proc_cpu.sh ends
