#!/bin/bash -e
##-------------------------------------------------------------------
## File : list_http_traffic.sh
## Author : DennyZhang.com <contact@dennyzhang.com>
## Description :
## --
## Created : <2016-06-14>
## Updated: Time-stamp: <2017-09-04 18:54:38>
##-------------------------------------------------------------------
## env variables:
##      server_list:
##         192.168.1.2:2703
##         192.168.1.3:2704
##      env_parameters:
##          export FORCE_RESTART_JUSTNIFFER_PROCESS=false
##          export STOP_JUSTNIFFER_PROCESS=false
##          export TRAFFIC_LOG_FILE="/root/justniffer.log"
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
function remote_install_justniffer() {
    local ssh_connect=${1?}
    if $ssh_connect "! which justniffer 1>/dev/null 2>&1"; then
        echo "========== install justniffer"

        command="add-apt-repository -y ppa:oreste-notelli/ppa"
        echo "$command" && $ssh_connect "$command"

        command="apt-get -y update"
        echo "$command" && $ssh_connect "$command"

        command="apt-get install -y justniffer"
        echo "$command" && $ssh_connect "$command"
    fi
}

function shell_exit() {
    errcode=$?
    for server in ${server_list}; do
        server_split=(${server//:/ })
        server_ip=${server_split[0]}
        server_port=${server_split[1]}
        ssh_username=${server_split[2]}
        [ -n "$ssh_username" ] || ssh_username="root"

        ssh_connect="ssh -i $ssh_key_file -p $server_port -o StrictHostKeyChecking=no $ssh_username@$server_ip"
        command="grep -v '^-' $TRAFFIC_LOG_FILE | grep -v ' - - ' | tail -n$TAIL_COUNT"
        # tolerant for no matched entries
        echo -e "\n========== Show network traffic report on $server\nRun: $command" && $ssh_connect "$command || true"

        if [ "$STOP_JUSTNIFFER_PROCESS" = "true" ]; then
            remote_stop_process "$ssh_connect"
        fi
    done
    exit $errcode
}

################################################################################################
trap shell_exit SIGHUP SIGINT SIGTERM 0
source_string "$env_parameters"

# TODO: check remote server: only support ubuntu

[ -n "$ssh_key_file" ] || ssh_key_file="$HOME/.ssh/id_rsa"
[ -n "$FORCE_RESTART_JUSTNIFFER_PROCESS" ] || FORCE_RESTART_JUSTNIFFER_PROCESS=false
[ -n "$STOP_JUSTNIFFER_PROCESS" ] || STOP_JUSTNIFFER_PROCESS=false
[ -n "$TRAFFIC_LOG_FILE" ] || TRAFFIC_LOG_FILE="/root/justniffer.log"
[ -n "$TAIL_COUNT" ] || TAIL_COUNT="500"

start_command="nohup /usr/bin/justniffer -i eth0 -l '%request.timestamp(%T %D) %request.header.host - %response.time' >> $TRAFFIC_LOG_FILE 2>&1 &"

server_list=$(string_strip_comments "$server_list")
server_list=$(string_strip_whitespace "$server_list")

# Input Parameters check
verify_comon_jenkins_parameters

# TODO: reduce code duplication in this loop
for server in ${server_list}; do
    server_split=(${server//:/ })
    server_ip=${server_split[0]}
    server_port=${server_split[1]}
    ssh_username=${server_split[2]}
    [ -n "$ssh_username" ] || ssh_username="root"
    ssh_connect="ssh -i $ssh_key_file -p $server_port -o StrictHostKeyChecking=no $ssh_username@$server_ip"

    echo "========== Setup on $server"
    remote_install_justniffer "$ssh_connect"
    if [ "$FORCE_RESTART_JUSTNIFFER_PROCESS" = "true" ]; then
        $ssh_connect "rm -rf $TRAFFIC_LOG_FILE"
        remote_stop_process "$ssh_connect" "justniffer"
    fi
    remote_start_process "$ssh_connect" "justniffer" "$start_command"
done
## File : list_http_traffic.sh ends
