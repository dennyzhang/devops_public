#!/bin/bash -e
##-------------------------------------------------------------------
## File: check_proc_cpu.sh
## Author : Denny <denny.zhang001@gmail.com>
## Description :
## --
##
## Link: http://www.dennyzhang.com/nagois_monitor_process_cpu
##
## Created : <2015-02-25>
## Updated: Time-stamp: <2015-05-22 20:01:57>
##-------------------------------------------------------------------
if [ "$1" = "-w" ] && [ "$2" -gt "0" ] && \
    [ "$3" = "-c" ] && [ "$4" -gt "0" ]; then
    pidPattern=${5?"specify how to get pid"}

    if [ "$pidPattern" = "--pidfile" ]; then
        pidfile=${6?"pidfile to get pid"}
        pid=$(cat $pidfile)
    elif [ "$pidPattern" = "--cmdpattern" ]; then
        cmdpattern=${6?"command line pattern to find out pid"}
        pid=$(ps -ef | grep "$cmdpattern" | grep -v grep | grep -v check_proc_cpu.sh | head -n 1 | awk -F' ' '{print $2}')
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

    cpuUsage=`ps -p $pid -o %cpu | tail -n 1 | sed -e 's/^[ \t]*//'`

    if [ $(echo "$cpuUsage>$4" | bc) -eq 1 ]; then
        echo "Critical CPU used by process($pid) is $cpuUsage % is more than $4 %!|CPU=$cpuUsage"
        $(exit 2)
    elif [ $(echo "$cpuUsage>$2" | bc) -eq 1 ]; then
        echo "Warning CPU used by process($pid) is $cpuUsage % is more than $2 %!|CPU=$cpuUsage"
        $(exit 1)
    else
        echo "OK CPU used by process($pid) is $cpuUsage %|CPU=$cpuUsage"
        $(exit 0)
    fi

else
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
    echo "Copyright (C) 2015 DennyZhang (denny.zhang001@gmail.com)"
    exit
fi
## File - check_proc_cpu.sh ends
