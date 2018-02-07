#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : run_remote_command.sh
## Author : DennyZhang.com <contact@dennyzhang.com>
## Description :
## --
## Created : <2016-04-13>
## Updated: Time-stamp: <2017-09-04 18:54:39>
##-------------------------------------------------------------------

################################################################################################
## env variables:
##      command_list:
##        172.17.0.1:22:root:echo hello
##        172.17.0.1:23:root:rm /tmp/npm-*
##
##       env_parameters:
##         export ssh_key_file="$HOME/.ssh/id_rsa"
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
source_string "$env_parameters"

[ -n "$ssh_key_file" ] || export ssh_key_file="$HOME/.ssh/id_rsa"

command_list=$(string_strip_comments "$command_list")
# TODO: verify command_list is valid, in case users have wrong input
# Input Parameters check
verify_comon_jenkins_parameters
check_list_fields "STRING:TCP_PORT:STRING:STRING" "$command_list"

IFS=$'\n'
for command_item in ${command_list[*]}; do
    unset IFS

    IFS=:
    item=($command_item)
    unset IFS

    server_ip=${item[0]}
    server_port=${item[1]}
    ssh_username=${item[2]}
    string_prefix="$server_ip:$server_port:$ssh_username:"
    bash_command="${command_item#${string_prefix}}"

    ssh_connect="ssh -i $ssh_key_file -p $server_port -o StrictHostKeyChecking=no $ssh_username@$server_ip"
    echo "=============== $ssh_connect $bash_command"
    $ssh_connect "$bash_command"
done
## File : run_remote_command.sh ends
