#!/bin/bash
##-------------------------------------------------------------------
## File : enforce_all_nagios_check.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
## --
## Created : <2015-06-24>
## Updated: Time-stamp: <2016-04-09 09:35:43>
##-------------------------------------------------------------------
skip_check_pattern=${1:-""}
ignore_check_warn=${2:-"0"}
nagios_check_dir=${3:-""}

if [ -z "$nagios_check_dir" ]; then
    server_name=`hostname`
    nagios_check_dir="/etc/nagios3/conf.d/$server_name"
fi

if [ ! -d $nagios_check_dir ]; then
    echo "ERROR: $nagios_check_dir doesn't exist"
    exit 1
fi
cd $nagios_check_dir

failed_checks=""
skipped_checks=""
IFS=$'\n'
for f in `ls -1 *.cfg`; do
    if grep '^ *host_name *' $f 2>/dev/null 1>/dev/null; then
        host_name=$(grep '^ *host_name *' $f | awk -F' ' '{print $2}' | head -n 1)
        for check in `grep '^ *check_command' $f | awk -F' ' "{print $2}" | awk -F'!' '{print $2}'`; do
            command="/usr/lib/nagios/plugins/check_nrpe -H $host_name -c $check"
            if [ -n "$skip_check_pattern" ]; then
                if echo $check | grep -iE "$skip_check_pattern" 2>/dev/null 1>/dev/null; then
                    echo "skip check: $command"
                    skipped_checks="${skipped_checks}${check};"
                    continue
                fi
            fi
            echo $command
            output=`eval $command`
            errcode=$?
            # check fail
            if [ $errcode -ge 2 ]; then
                failed_checks="${failed_checks}${check};"
                echo "Error check: $check. output: $output"
            fi

            if [ $errcode -eq 1 ]; then
                if [ "$ignore_check_warn" = "1" ] && echo $output | grep WARN 2>&1 1>/dev/null; then
                    echo "skip failed warn check: $command"
                    skiped_checks="${skiped_checks}${check};"
                    continue
                else
                    failed_checks="${failed_checks}${check};"
                    echo "Error check: $check. output: $output"
                fi
            fi
        done
    fi
done
unset IFS

echo -ne "========================================================\n"
if [ -n "$skipped_checks" ]; then
    echo "Skipped_checks:"
    echo "$skipped_checks"
fi
if [ -n "$failed_checks" ]; then
    echo "Failed_checks:"
    echo "$failed_checks"
    exit 1
else
    echo "All checks pass"
    exit 0
fi
## File : enforce_all_nagios_check.sh ends
