#!/bin/bash
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : enforce_all_nagios_check.sh
## Author : Denny <contact@dennyzhang.com>, Syrett <syrett_uu@dennyzhang.com>
## Description :
##     ./enforce_all_nagios_check.sh help
##     ./enforce_all_nagios_check.sh -s "check_.*_log|check_memory|check_tomcat_cpu"
## --
## Created : <2016-06-04>
## Updated: Time-stamp: <2017-09-04 18:54:43>
##-------------------------------------------------------------------

function check_one_server(){
    local nagios_check_dir=${1}
    local skip_check_pattern=${2}
    cd "$nagios_check_dir" || exit 1
    
    local failed_checks=""
    local skipped_checks=""
    IFS=$'\n'
    for f in *.cfg; do
        if grep '^ *host_name *' "$f" 1>/dev/null 2>&1; then
            host_name=$(grep '^ *host_name *' "$f" | awk -F' ' '{print $2}' | head -n 1)
            while IFS= read -r line
            do
                check=$(echo "$line" | awk -F' ' '{print $2}' | awk -F'!' '{print $2}')
                command="/usr/lib/nagios/plugins/check_nrpe -H $host_name -c $check"
                if [ -n "$skip_check_pattern" ]; then
                    if echo "$check" | grep -iE "$skip_check_pattern" 1>/dev/null 2>&1; then
                        echo "skip check: $command"
                        skipped_checks="${skipped_checks}${check};"
                        continue
                    fi
                fi
                echo "$command"
                output=$(eval "$command")
                errcode=$?
                # check fail
                if [ $errcode -ge 2 ]; then
                    failed_checks="${failed_checks}${check};"
                    echo "Error check: $check. output: $output"
                fi
                
                if [ $errcode -eq 1 ]; then
                    if [ "$ignore_check_warn" = "1" ] && echo "$output" | grep WARN 1>/dev/null 2>&1; then
                        echo "skip failed warn check: $command"
                        skiped_checks="${skiped_checks}${check};"
                        continue
                    else
                        failed_checks="${failed_checks}${check};"
                        echo "Error check: $check. output: $output"
                    fi
                fi
            done < <(grep '^ *check_command' < "$f")
        fi
    done
    unset IFS

    if [ -n "$skipped_checks" ]; then
        echo "Skipped_checks:"
        echo "$skipped_checks"
    fi
    if [ -n "$failed_checks" ]; then
        echo "Failed_checks:"
        echo "$failed_checks"
        my_result="failed"
    else
        echo "All checks pass"
        my_result="success"
    fi
}

while [[ $# -gt 1 ]]
do
    opt="$1"
    case $opt in
        -s|--skip_check_pattern)
            skip_check_pattern="$2"
            shift
            ;;
        -w|--ignore_check_warn)
            ignore_check_warn="$2"
            shift
            ;;
        -c|--conf_check_dir)
            conf_check_dir="$2"
            shift
            ;;        
        -n|--server_names)
            server_names="$2"
            shift
            ;;
        *)
            echo "Invalid options: $opt
DESCRIPTION
    enforce all nagios to check

The following options are available:
    -s,--skip_check_pattern: skip some check
    -w,--ignore_check_warn: ignore check warn
    -c,--conf_check_dir: check the conf_dir's all check, default value:/etc/nagios3/conf.d
    -n,--server_names: \$servername1,\$servername2. only check \${conf_check_dir}/\${server_names}'s all check, default value: /etc/nagios3/conf.d/\${server_names}
"
            exit 1
            ;;
    esac
    shift
done

if [ -z "${ignore_check_warn}" ]; then
    ignore_check_warn="0"
fi

if [ -z "${conf_check_dir}" ]; then
    conf_check_dir="/etc/nagios3/conf.d"
fi

if [ -z "${server_names}" ]; then
    files=$(ls -l /etc/nagios3/conf.d/)
    server_list=$(echo "$files" | grep '^d' | awk '{print $NF}')
else
    server_list=(${server_names//,/ })    
fi

nagios_check_result=0

echo -ne "==============================================================================\n"
echo -ne "                             Run Nagios Check\n"
echo -ne "==============================================================================\n"
for server in ${server_list[*]}
do
    nagios_check_dir="$conf_check_dir/$server"
    cd "$nagios_check_dir" || exit 1
    echo -ne "---------------------------$server-----------------------------\n"
    if [ ! -d "$nagios_check_dir" ]; then
        echo "ERROR: $nagios_check_dir doesn't exist"
        continue
    fi
    my_result="failed"
    check_one_server "$nagios_check_dir" "$skip_check_pattern"

    if [ $my_result != "success" ];then
        nagios_check_result=1
    fi
done

echo -ne "==============================================================================\n"
echo -ne "                               nagios checks end                              \n"
echo -ne "==============================================================================\n"
if [ $nagios_check_result -eq 0 ];then
    echo "ALL Server's Nagios Check success!"
else
    echo "Nagios Check failed!"
fi

exit $nagios_check_result

## File : enforce_all_nagios_check.sh ends
