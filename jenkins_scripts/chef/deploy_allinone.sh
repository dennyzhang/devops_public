#!/bin/bash -ex
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : deploy_allinone.sh
## Author : DennyZhang.com <contact@dennyzhang.com>
## Description :
## --
## Created : <2015-08-05>
## Updated: Time-stamp: <2018-02-07 16:26:41>
################################################################################################
## Purpose: General function to deploy all-in-one env by chef
##
## env variables:
##       ssh_server_ip: 123.57.240.189
##       ssh_port: 6022
##       chef_json:
##             {
##               "run_list": ["recipe[all-in-one-auth]"],
##               "os_basic_auth":{"repo_server":"123.57.240.189:28000"},
##               "all_in_one_auth":{"branch_name":"dev",
##               "install_audit":"1"}
##             }
##       chef_client_rb: cookbook_path ["/root/test/dev/mydevops/cookbooks","/root/test/dev/mydevops/community_cookbooks"]
##       check_command: enforce_all_nagios_check.sh -s "check_.*_log|check_.*_cpu"
##       devops_branch_name: dev
##       env_parameters:
##             export STOP_CONTAINER=false
##             export KILL_RUNNING_CHEF_UPDATE=false
##             export START_COMMAND="docker start longrun-aio"
##             export POST_START_COMMAND="sleep 5; service apache2 start; true"
##             export PRE_STOP_COMMAND="service apache2 stop; true"
##             export STOP_COMMAND="docker stop longrun-aio"
##             export EXIT_NODE_CONNECT_FAIL=true
##             export CODE_SH=""
##             export SSH_SERVER_PORT=22
##             export CHEF_BINARY_CMD=chef-client
##
## Hook points: START_COMMAND -> POST_START_COMMAND -> PRE_STOP_COMMAND -> STOP_COMMAND
################################################################################################
. /etc/profile
[ -n "$DOWNLOAD_TAG_NAME" ] || export DOWNLOAD_TAG_NAME="tag_v6"
export DOWNLOAD_PREFIX="https://raw.githubusercontent.com/DennyZhang/devops_public/${DOWNLOAD_TAG_NAME}"
if [ ! -f /var/lib/devops/refresh_common_library.sh ]; then
    [ -d /var/lib/devops/ ] || (mkdir -p /var/lib/devops/ && chmod 777 /var/lib/devops)
    wget -O /var/lib/devops/refresh_common_library.sh "$DOWNLOAD_PREFIX/common_library/refresh_common_library.sh"
    chmod 777 /var/lib/devops/refresh_common_library.sh
fi
bash /var/lib/devops/refresh_common_library.sh "3536991806" "/var/lib/devops/devops_common_library.sh" \
     "${DOWNLOAD_PREFIX}/common_library/devops_common_library.sh"
. /var/lib/devops/devops_common_library.sh
################################################################################################
function shell_exit() {
    errcode=$?
    if $STOP_CONTAINER; then
        if [ -n "$PRE_STOP_COMMAND" ]; then
            ssh_pre_stop_command="ssh $common_ssh_options -p $ssh_port root@$ssh_server_ip \"$PRE_STOP_COMMAND\""
            log "$ssh_pre_stop_command"
            eval "$ssh_pre_stop_command"
        fi

        log "stop container."
        ssh_stop_command="ssh $common_ssh_options -p $SSH_SERVER_PORT root@$ssh_server_ip \"$STOP_COMMAND\""
        log "$ssh_stop_command"
        eval "$ssh_stop_command"

    fi
    exit $errcode
}

########################################################################
trap shell_exit SIGHUP SIGINT SIGTERM 0
source_string "$env_parameters"

echo "Deploy to ${ssh_server_ip}:${ssh_port}"

if [ -n "$STOP_CONTAINER" ] && $STOP_CONTAINER; then
    ensure_variable_isset "When STOP_CONTAINER is set, STOP_COMMAND must be given " "$STOP_COMMAND"
fi

log "env variables. KILL_RUNNING_CHEF_UPDATE: $KILL_RUNNING_CHEF_UPDATE, STOP_CONTAINER: $STOP_CONTAINER"

# TODO: use chef-zero, instead of chef-solo
#[ -n "${CHEF_BINARY_CMD}" ] || CHEF_BINARY_CMD=chef-client
[ -n "${CHEF_BINARY_CMD}" ] || CHEF_BINARY_CMD=chef-solo
[ -n "$ssh_key_file" ] || ssh_key_file="$HOME/.ssh/id_rsa"
[ -n "$code_dir" ] || code_dir="/root/test"
[ -n "$SSH_SERVER_PORT" ] || SSH_SERVER_PORT=22
[ -n "$EXIT_NODE_CONNECT_FAIL" ] || EXIT_NODE_CONNECT_FAIL=true

kill_chef_command="killall -9 $CHEF_BINARY_CMD || true"

if [ -n "$CODE_SH" ]; then
    ensure_variable_isset "Error: when CODE_SH is not empty, git_repo_url can't be empty" "$git_repo_url"
fi

# Input Parameters check
# check_list_fields "IP" "$ssh_server_ip"
check_list_fields "TCP_PORT" "$ssh_port"
enforce_ssh_check "$EXIT_NODE_CONNECT_FAIL" "$ssh_server_ip:$ssh_port" "$ssh_key_file"

if [ -z "$chef_client_rb" ]; then
    git_repo=$(parse_git_repo "$git_repo_url")
    chef_client_rb="cookbook_path [\"$code_dir/$devops_branch_name/$git_repo/cookbooks\",\"$code_dir/$devops_branch_name/$git_repo/community_cookbooks\"]"
else
    chef_client_rb=$(echo "$chef_client_rb" | sed -e "s/ +/ /g")
fi

export common_ssh_options="-i $ssh_key_file -o StrictHostKeyChecking=no "

########################################################################
if [ -n "$START_COMMAND" ]; then
    ssh_start_command="ssh $common_ssh_options -p $SSH_SERVER_PORT root@$ssh_server_ip \"$START_COMMAND\""
    log "$ssh_start_command"
    eval "$ssh_start_command"

    sleep 2

    if [ -n "$POST_START_COMMAND" ]; then
        ssh_post_start_command="ssh $common_ssh_options -p $ssh_port root@$ssh_server_ip \"$POST_START_COMMAND\""
        log "$ssh_post_start_command"
        eval "$ssh_post_start_command"
    fi
fi

if $KILL_RUNNING_CHEF_UPDATE; then
    log "$kill_chef_command"
    ssh -i "$ssh_key_file" -p "$ssh_port" -o StrictHostKeyChecking=no "root@$ssh_server_ip" "\$kill_chef_command"
fi

if [ -n "$CODE_SH" ]; then
    log "Update git codes"
    git_repo=$(parse_git_repo "$git_repo_url")
    # ssh -i $ssh_key_file -p $ssh_port -o StrictHostKeyChecking=no root@$ssh_server_ip $CODE_SH $code_dir $git_repo_url $git_repo $devops_branch_name
    # TODO: remove this line and replace to above
    ssh -i "$ssh_key_file" -p "$ssh_port" -o StrictHostKeyChecking=no "root@$ssh_server_ip" "$CODE_SH" "$code_dir" "$git_repo_url" "$devops_branch_name" "all-in-one"
fi

# TODO: replace deployment logic by chef_deploy function
chef_json=$(string_strip_comments "$chef_json")
log "Prepare chef configuration"
cat > /tmp/client.rb <<EOF
file_cache_path "/var/chef/cache"
$chef_client_rb
EOF

echo "$chef_json" > /tmp/client.json

scp -i "$ssh_key_file" -P "$ssh_port" -o StrictHostKeyChecking=no /tmp/client.rb "root@$ssh_server_ip:/root/client.rb"
scp -i "$ssh_key_file" -P "$ssh_port" -o StrictHostKeyChecking=no /tmp/client.json "root@$ssh_server_ip:/root/client.json"

log "Apply chef update"
# TODO: use chef-zero, instead of chef-solo
# ssh_command="ssh -i $ssh_key_file -p $ssh_port -o StrictHostKeyChecking=no root@$ssh_server_ip $CHEF_BINARY_CMD --config /root/client.rb -j /root/client.json --local-mode"
ssh_command="ssh -i $ssh_key_file -p $ssh_port -o StrictHostKeyChecking=no root@$ssh_server_ip $CHEF_BINARY_CMD --config /root/client.rb -j /root/client.json"

log "$ssh_command"
$ssh_command

if [ -n "$check_command" ]; then
    log "Run Check Command: $check_command"
    ssh_command="ssh -i $ssh_key_file -p $ssh_port -o StrictHostKeyChecking=no root@$ssh_server_ip $check_command"
    $ssh_command
fi
## File : deploy_allinone.sh ends
