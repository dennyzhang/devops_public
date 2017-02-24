#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File: check_proc_mem.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
## --
##
## Link: http://www.dennyzhang.com/nagois_monitor_process_memory
##
## Created : <2014-10-25>
## Updated: Time-stamp: <2016-12-06 21:45:58>
##-------------------------------------------------------------------

while getopts w:c:p:e:vi: name
do
    case $name in
    w)  warning="$OPTARG";;
    c)  critical="$OPTARG";;
    p)  pidfile="$OPTARG";;
    e)  cmdpattern="$OPTARG";;
    i)  procpid="$OPTARG";;
    v)  verbose=true;;
    ?)  printf " USAGE: check_proc_mem.sh -w WARNING_VALUE -c CRITICAL_VALUE {-p pidfile | -c cmdpattern | -i pid} \n \
" $0
            exit 1;;
    esac
done

if ! [ -z "$warning" -o -z "$critical" -o -z "$pidfile" -a -z "$cmdpattern" -a -z "$procpid" ];then
    if [ -n "$pidfile" ]; then
        pid=$(cat "$pidfile")
        [ $verbose ] && echo $pid
    elif [ -n "$cmdpattern" ]; then
        pid=$(pgrep -a -f "$cmdpattern" | grep -v check_proc_mem.sh | head -n 1 | awk -F' ' '{print $1}')
        [ $verbose ] && echo $pid
    elif [ -n "$procpid" ]; then
        pid=${procpid}
        [ $verbose ] && echo $pid
    else
        echo "ERROR input for pidpattern"
        exit 2
    fi

    if [ -z "$pid" ]; then
        echo "ERROR: no related process is found"
        exit 2
    fi

    memVmSize=$(grep 'VmSize:' "/proc/${pid}/status" | awk -F' ' '{print $2}')
    memVmSize=$((memVmSize/1024))

    memVmRSS=$(grep 'VmRSS:' "/proc/${pid}/status" | awk -F' ' '{print $2}')
    memVmRSS=$((memVmRSS/1024))

    if [ "$memVmRSS" -ge "$critical" ]; then
        echo "Memory: CRITICAL RES: $memVmRSS MB - VIRT: $memVmSize MB used!|RES=$((memVmRSS*1024*1024));;;;"
        exit 2
    elif [ "$memVmRSS" -ge "$warning" ]; then
        echo "Memory: WARNING RES: $memVmRSS MB - VIRT: $memVmSize MB used!|RES=$((memVmRSS*1024*1024));;;;"
        exit 1
    else
        echo "Memory: OK RES: $memVmRSS MB - VIRT: $memVmSize MB!|RES=$((memVmRSS*1024*1024));;;;"
        exit 0
    fi

else
    echo "check_proc_mem v1.1"
    echo ""
    echo "Usage:"
    echo "check_proc_mem.sh -w <warn_MB> -c <criti_MB> -p <pid_file>  or -e  <cmdpattern> or -i <pid>"
    echo ""
    echo "Below: If tomcat use more than 1024MB resident memory, send warning"
    echo "check_proc_mem.sh -w 1024 -c 2048 -p /var/run/tomcat7.pid"
    echo "check_proc_mem.sh -w 1024 -c 2048 -i 11325"
    echo "check_proc_mem.sh -w 1024 -c 2048 -e \"tomcat7.*java.*Dcom\""
    echo ""
    echo "Copyright (C) 2014 DennyZhang (denny@dennyzhang.com)"
    exit
fi
## File - check_proc_mem.sh ends
