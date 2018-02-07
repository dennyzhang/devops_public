#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : deploy_cluster.sh
## Author : DennyZhang.com <contact@dennyzhang.com>
## Description :
## --
## Created : <2015-07-03>
## Updated: Time-stamp: <2017-09-04 18:54:40>
##-------------------------------------------------------------------
################################################################################################
## env variables:
##       server_list: ip-1:port-1
##                    ip-2:port-2
##       deploy_run_list: "recipe[apt::default]","recipe[cluster-auth::multi_instance]"
##       init_run_list: "recipe[apt::default]","recipe[cluster-auth::initialize]"
##       chef_client_rb: cookbook_path ["/root/test/mydevops/cookbooks","/root/test/mydevops/community_cookbooks"]
##       chef_json:
##        {"os_basic_auth":
##                {"enable_firewall": "0",
##                "repo_server": "104.236.159.226:18000"},
##        "common_auth":
##                {"package_url": "http://172.17.42.1:28000/dev",
##                "rubygem_source": "http://rubygems.org/",
##                "service_list":["mongodb", "elasticsearch", "kibana", "logstash", "logstash_forwarder", "ldap", "redis", "mfa", "audit", "account", "message", "authz", "oauth2", "configuration", "ssoportal", "gateway", "docmgrpoc", "tenantadmin", "configuration_setup", "store_rest", "tomcat", "nginx", "haproxy"],
##                "nginx_host": "devops-cluster-nginx",
##                "haproxy_host": "devops-cluster-ha",
##                "mongodb_host": "devops-cluster-database-1",
##                "elasticsearch_host": "devops-cluster-database-1",
##                "kibana_hosts": ["devops-cluster-backend-1","devops-cluster-backend-2"],
##                "logstash_host": "devops-cluster-database-1",
##                "logstash_forwarder_hosts": ["devops-cluster-backend-1","devops-cluster-backend-2","devops-cluster-frontend-1","devops-cluster-frontend-2"],
##                "ldap_server_host": "devops-cluster-database-1",
##                "redis_host": "devops-cluster-database-1",
##                "tomcat":
##                     {"hosts": ["devops-cluster-backend-1","devops-cluster-backend-2", "devops-cluster-frontend-1","devops-cluster-frontend-2"]}}
##      }
##
##       check_command: enforce_all_nagios_check.sh -s "check_.*_log|check_.*_cpu"
##       devops_branch_name: dev
##       ssh_private_key: XXX
##           # ssh id_rsa private key to login servers without password
##       env_parameters:
##             export KILL_RUNNING_CHEF_UPDATE=false
##             export EXIT_NODE_CONNECT_FAIL=true
##             export CHEF_BINARY_CMD=chef-client
##             export CODE_SH="/root/mydevops/misc/git_update.sh"
##             export START_COMMAND="ssh root@172.17.0.1 docker start kitchen-cluster-node1 kitchen-cluster-node2"
##             export POST_START_COMMAND="sleep 5; service apache2 start; true"
##             export PRE_STOP_COMMAND="service apache2 stop; true"
##             export STOP_COMMAND="ssh root@172.17.0.1 docker stop kitchen-cluster-node1 kitchen-cluster-node2"
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
function init_cluster() {
    local server=${1?}

    log "Initialize to $server"
    local server_split=(${server//:/ })
    local ssh_server_ip=${server_split[0]}
    local ssh_port=${server_split[1]}

    log "Prepare chef configuration"
    echo "$chef_client_rb" > /tmp/client_init.rb
    echo -e "{\n\"run_list\": [${init_run_list}],\n${chef_json}\n}" > /tmp/client_init.json

    ssh_command="scp $common_ssh_options -P $ssh_port /tmp/client_init.rb root@$ssh_server_ip:/root/client_init.rb"
    $ssh_command

    ssh_command="scp $common_ssh_options -P $ssh_port /tmp/client_init.json root@$ssh_server_ip:/root/client_init.json"
    $ssh_command

    log "Apply chef update"
    ssh_command="ssh $common_ssh_options -p $ssh_port root@$ssh_server_ip $CHEF_BINARY_CMD --config /root/client_init.rb -j /root/client_init.json"
    $ssh_command

    log "Initialize $server end"
}

function check_command() {
    local server=${1?}

    local server_split=(${server//:/ })
    local ssh_server_ip=${server_split[0]}
    local ssh_port=${server_split[1]}
    log "check server:${ssh_server_ip}:${ssh_port}"
    ssh_command="ssh $common_ssh_options -p $ssh_port root@$ssh_server_ip"
    $ssh_command "$check_command"
}

function shell_exit() {
    errcode=$?
    if $STOP_CONTAINER; then
        if [ -n "$PRE_STOP_COMMAND" ]; then
            log "$PRE_STOP_COMMAND"
            eval "$PRE_STOP_COMMAND"
        fi

        log "$STOP_COMMAND"
        eval "$STOP_COMMAND"
    fi
    exit $errcode
}
##########################################################################################
trap shell_exit SIGHUP SIGINT SIGTERM 0
source_string "$env_parameters"

server_list=$(string_strip_comments "$server_list")
server_list=$(string_strip_whitespace "$server_list")
echo "server_list: ${server_list}"

[ -n "$ssh_key_file" ] || export ssh_key_file="$HOME/.ssh/ci_id_rsa"
[ -n "$KILL_RUNNING_CHEF_UPDATE" ] || export KILL_RUNNING_CHEF_UPDATE=false
[ -n "$EXIT_NODE_CONNECT_FAIL" ] || export EXIT_NODE_CONNECT_FAIL=true
[ -n "$code_dir" ] || code_dir="/root/test"
# TODO: use chef-zero, instead of chef-solo
#[ -n "$CHEF_BINARY_CMD" ] || CHEF_BINARY_CMD=chef-client
[ -n "$CHEF_BINARY_CMD" ] || CHEF_BINARY_CMD=chef-solo
git_repo=$(parse_git_repo "$git_repo_url")

export common_ssh_options="-i $ssh_key_file -o StrictHostKeyChecking=no "
if [ -z "$chef_client_rb" ]; then
    chef_client_rb="cookbook_path [\"$code_dir/$devops_branch_name/$git_repo/cookbooks\",\"$code_dir/$devops_branch_name/$git_repo/community_cookbooks\"]"
fi

chef_json=$(parse_json "$chef_json")

if [ -n "$STOP_CONTAINER" ] && $STOP_CONTAINER; then
    ensure_variable_isset "When STOP_CONTAINER is set, STOP_COMMAND must be given " "$STOP_COMMAND"
fi
if [ -n "$CODE_SH" ]; then
    ensure_variable_isset "Error: when CODE_SH is not empty, git_repo_url can't be empty" "$git_repo_url"
fi

# Input parameters check
verify_comon_jenkins_parameters
enforce_ip_ping_check "$EXIT_NODE_CONNECT_FAIL" "chef_json" "$chef_json"

################################################################################
log "env variables. KILL_RUNNING_CHEF_UPDATE: $KILL_RUNNING_CHEF_UPDATE, STOP_CONTAINER: $STOP_CONTAINER"
inject_ssh_key "$ssh_private_key" "$ssh_key_file"

if [ -n "$START_COMMAND" ]; then
    log "$START_COMMAND"
    eval "$START_COMMAND"

    sleep 2

    if [ -n "$POST_START_COMMAND" ]; then
        log "$POST_START_COMMAND"
        eval "$POST_START_COMMAND"
    fi
fi

bindhosts "$server_list" "$ssh_key_file"

# update code
for server in ${server_list}; do
    server_split=(${server//:/ })
    ssh_server_ip=${server_split[0]}
    ssh_port=${server_split[1]}

    if ${KILL_RUNNING_CHEF_UPDATE}; then
        # TODO: what if $CHEF_BINARY_CMD has whitespace?
        log "ps -ef | grep ${CHEF_BINARY_CMD} || killall -9 ${CHEF_BINARY_CMD}"
        ssh_command="ssh $common_ssh_options -p $ssh_port root@$ssh_server_ip killall -9 $CHEF_BINARY_CMD || true"
        $ssh_command
    fi

    if [ -n "${CODE_SH}" ]; then
        ssh_command="ssh $common_ssh_options -p $ssh_port root@$ssh_server_ip $CODE_SH $code_dir $git_repo_url $devops_branch_name"
        log "Update git code for $ssh_server_ip:$ssh_port"
        $ssh_command
    fi
done

# perform backup
if [ -n "$backup_run_list" ]; then
    log "Start to backup"
    for server in ${server_list}; do
        echo "TODO: implement logic"
    done
    log "Backup End"
fi

# deployment
if [ -n "$deploy_run_list" ]; then
    for server in ${server_list}; do
        log "Star to Deploy cluster: $server"
        chef_deploy "$server" "$CHEF_BINARY_CMD" "$deploy_run_list" "$chef_json" "$chef_client_rb"
    done

    log "Deploy End"
fi

# initialize cluster
if [ -n "$init_run_list" ]; then
    log "Star to Initialize cluster"
    for server in ${server_list}; do
        init_cluster "$server"
    done
    log "Initialize End"
fi

# restart services
if [ -n "$restart_run_list" ]; then
    for server in ${server_list}; do
        echo "TODO: implement logic"
    done
fi

# check system status
if [ -n "$check_command" ]; then
    log "Start to check: $check_command"
    for server in ${server_list}; do
        check_command "$server"
    done
    log "Check End"
fi
## File : deploy_cluster.sh ends
