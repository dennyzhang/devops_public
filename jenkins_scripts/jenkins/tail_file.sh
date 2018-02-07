#!/bin/bash -e
################################################################################################
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : tail_file.sh
## Author : Denny <contact@dennyzhang.com>
## Description : collect the files across servers, and transfer to specific destination
## --
## Created : <2016-04-14>
## Updated: Time-stamp: <2017-09-04 18:54:38>
##-------------------------------------------------------------------

################################################################################################
## env variables:
##      ssh_server: 172.17.0.2:22:root
##
##      file_list:
##         # Jenkins backup
##         eval: find $HOME/jobs -name config.xml
##         # Confluence backup
##         eval: find /var/atlassian/application-data/confluence/backups/ -name *.zip | head -n 1
##         # JIRA backup
##         eval: find /var/atlassian/application-data/jira/export/ -name *.zip | head -n 1
##         # Gitlab backup
##         eval: find /var/opt/gitlab/backups -name *.tar | head -n 1
##
##      env_parameters:
##          export TAIL_LINE_COUNT=200
##          export ssh_key_file="$HOME/.ssh/id_rsa"
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
function tail_files() {
    local ssh_server_ip=${1?}
    local ssh_port=${2?}
    local ssh_username=${3?}
    local file_list=${4?}

    local ssh_connect="ssh -i $ssh_key_file -p $ssh_port -o StrictHostKeyChecking=no $ssh_username@$ssh_server_ip"

    # loop file_list
    IFS=$'\n'
    for t_file in ${file_list[*]}; do
        unset IFS
        if [[ "$t_file" = "eval: "* ]]; then
            echo "Evaluate file list: $t_file"
            local eval_command=${t_file#"eval: "}
            # TODO: better way for temporarily disable "set -e"
            set +e            
            ssh_result=$($ssh_connect "$eval_command")
            errcode=$?
            if [ $errcode -ne 0 ] || [ -z "$ssh_result" ]; then
                echo "Warning: Fail to run $eval_command"
            else
                tail_files "$ssh_server_ip" "$ssh_port" "$ssh_username" "$ssh_result"
            fi
            set -e
        else
            # remove tailing /: /opt/devops/ --> /opt/devops
            t_file=${t_file%/}
            echo -e "\n========= tail -n $TAIL_LINE_COUNT $t_file"
            ssh_result=$($ssh_connect test -r "$t_file" && echo yes || echo no)
            if [ "x$ssh_result" == "xno" ]; then
                echo "Warning: file [$t_file] not readable"
                continue
            fi

            $ssh_connect "tail -n $TAIL_LINE_COUNT $t_file"
        fi
    done
}
########################################################################
source_string "$env_parameters"

ensure_variable_isset "ERROR wrong parameter: ssh_server can't be empty" "$ssh_server"
ensure_variable_isset "ERROR wrong parameter: file_list can't be empty" "$file_list"

[ -n "$ssh_key_file" ] || export ssh_key_file="$HOME/.ssh/id_rsa"
export EXIT_NODE_CONNECT_FAIL=true

ssh_server=$(string_strip_comments "$ssh_server")
ssh_server=$(string_strip_whitespace "$ssh_server")

file_list=$(string_strip_comments "$file_list")
file_list=$(string_strip_whitespace "$file_list")

# Input Parameters check
verify_comon_jenkins_parameters

# Set default value
[ -n "$TAIL_LINE_COUNT" ] || export TAIL_LINE_COUNT="200"

# TODO: whitelist for security concern
server_split=(${ssh_server//:/ })
ssh_server_ip=${server_split[0]}
ssh_port=${server_split[1]}
ssh_username=${server_split[2]}
[ -n "$ssh_username" ] || ssh_username="root"

ssh_connect="ssh -i $ssh_key_file -p $ssh_port -o StrictHostKeyChecking=no $ssh_username@$ssh_server_ip"

tail_files "$ssh_server_ip" "$ssh_port" "$ssh_username" "$file_list"
## File : tail_file.sh ends
