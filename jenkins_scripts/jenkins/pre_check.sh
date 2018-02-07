#!/bin/bash -ex
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : pre_check.sh
## Description :
## --
## Created : <2015-10-27>
## Updated: Time-stamp: <2017-06-28 18:50:11>
##-------------------------------------------------------------------
################################################################################################
## env variables:
##         export MAX_CONNECT_NUMBER=5
##         export WEBSITE_LIST="https://bitbucket.org http://baidu.com"
##         export JENKINS_JOB_STATUS_FILES="CommonServerCheck.flag"
################################################################################################
. /etc/profile
[ -n "$DOWNLOAD_TAG_NAME" ] || export DOWNLOAD_TAG_NAME="tag_v6"
export DOWNLOAD_PREFIX="https://raw.githubusercontent.com/DennyZhang/devops_public/${DOWNLOAD_TAG_NAME}"
if [ ! -f /var/lib/devops/refresh_common_library.sh ]; then
    [ -d /var/lib/devops/ ] || (sudo mkdir -p /var/lib/devops/ && sudo chmod 777 /var/lib/devops)
    wget -O /var/lib/devops/refresh_common_library.sh "$DOWNLOAD_PREFIX/common_library/refresh_common_library.sh"
    chmod 777 /var/lib/devops/refresh_common_library.sh
fi
bash /var/lib/devops/refresh_common_library.sh "3536991806" "/var/lib/devops/devops_common_library.sh" \
     "${DOWNLOAD_PREFIX}/common_library/devops_common_library.sh"
. /var/lib/devops/devops_common_library.sh
################################################################################################
function shell_exit() {
    errcode=$?
    if [ $errcode -eq 0 ];then
        log "The pre_check has passed."
    else
        log "The pre_check has failed."
    fi
    exit $errcode
}

function check_jenkins_job_status()
{
    local status_files=${1:-"CommonServerCheck.flag"}
    local check_flag=true

    for flag_file_name in ${status_files[*]}; do
        local flag_file="$HOME/$flag_file_name"
        if test -f "$flag_file" ;then
            if [ "$(cat "$flag_file")" != "OK" ];then
                log "The status of $flag_file is ERROR."
                check_flag=false
            else
                log "The status of $flag_file is OK."
            fi
        else
            log "The flag file:$flag_file doesn't be found."
        fi
    done
    if ! $check_flag ;then
        exit 1
    fi
}
########################################################################
trap shell_exit SIGHUP SIGINT SIGTERM 0

source_string "$env_parameters"

if [ -n "$WEBSITE_LIST" ]; then
    #Check the network whether can connect.
    check_network "$MAX_CONNECT_NUMBER" "$WEBSITE_LIST"
fi

#Check the status of jenkins job:CommonServerCheck.
check_jenkins_job_status "$JENKINS_JOB_STATUS_FILES"
## File : pre_check.sh ends
