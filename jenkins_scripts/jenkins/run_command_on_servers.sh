#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : run_command_on_servers.sh
## Author : DennyZhang.com <contact@dennyzhang.com>
## Description :
## --
## Created : <2016-04-13>
## Updated: Time-stamp: <2017-09-04 18:54:39>
##-------------------------------------------------------------------

################################################################################################
## env variables:
##       server_list: ip-1:port-1:root
##                    ip-2:port-2:root
##       command_list:
##        cat /etc/hosts
##        ls /opt/
##
##       env_parameters:
##          export EXIT_NODE_CONNECT_FAIL=false
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
function shell_exit() {
    errcode=$?
    rm -rf "$tmp_file"
    if [ -n "$failed_servers" ]; then
        echo "=============== Failed server: $failed_servers"
        exit 1
    fi
    exit $errcode
}

function get_hostname_by_ssh() {
    local ssh_connect=${1?}
    ssh_command="$ssh_connect hostname"
    hostname=$(eval "$ssh_command")
    # TODO: improve error handling
    echo "$hostname" | grep -v "Warning"
}

################################################################################################
trap shell_exit SIGHUP SIGINT SIGTERM 0
source_string "$env_parameters"

[ -n "$ssh_key_file" ] || export ssh_key_file="$HOME/.ssh/id_rsa"
[ -n "$EXIT_NODE_CONNECT_FAIL" ] || export EXIT_NODE_CONNECT_FAIL=false

server_list=$(string_strip_comments "$server_list")
server_list=$(string_strip_whitespace "$server_list")
command=$(string_strip_comments "$command")

# Input Parameters check
verify_comon_jenkins_parameters

failed_servers=""
# Dump bash command to scripts
current_filename=$(basename "${0}")
tmp_file="/tmp/${current_filename}_$$"
cat > "$tmp_file" <<EOF
$command_list
EOF

# TODO: verify command_list is valid, in case users have wrong input
IFS=$'\n'
for server in ${server_list}; do
    unset IFS
    server_split=(${server//:/ })
    ssh_server_ip=${server_split[0]}
    ssh_port=${server_split[1]}
    ssh_username=${server_split[2]}
    [ -n "$ssh_username" ] || ssh_username="root"

    # TODO: support blacklist and whitelist mechanism
    ssh_command="scp -P $ssh_port -i $ssh_key_file -o StrictHostKeyChecking=no $tmp_file $ssh_username@$ssh_server_ip:/$tmp_file"
    $ssh_command

    ssh_connect="ssh -i $ssh_key_file -p $ssh_port -o StrictHostKeyChecking=no $ssh_username@$ssh_server_ip"
    ssh_command="$ssh_connect \"bash -ex $tmp_file\""
    hostname=$(get_hostname_by_ssh "$ssh_connect")
    echo -e "\n=============== Run Command on $hostname($ssh_server_ip:$ssh_port)"
    if ! eval "$ssh_command"; then
        failed_servers="${failed_servers} ${ssh_server_ip}:${ssh_port}"
    fi
done

# cleanup flagfiles
IFS=$'\n'
for server in ${server_list}; do
    unset IFS
    server_split=(${server//:/ })
    ssh_server_ip=${server_split[0]}
    ssh_port=${server_split[1]}
    ssh_username=${server_split[2]}
    [ -n "$ssh_username" ] || ssh_username="root"

    ssh_connect="ssh -i $ssh_key_file -p $ssh_port -o StrictHostKeyChecking=no $ssh_username@$ssh_server_ip"
    ssh_command="$ssh_connect rm -rf $tmp_file"
    eval "$ssh_command"
done
## File : run_command_on_servers.sh ends
