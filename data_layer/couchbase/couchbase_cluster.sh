#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
## https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : couchbase_cluster.sh
## Author : Denny <contact@dennyzhang.com>
## Description :
## --
## Created : <2016-06-04>
## Updated: Time-stamp: <2017-09-04 18:54:41>
##-------------------------------------------------------------------
cb_json="/tmp/$$.json"
function shell_exit() {
    errcode=$?
    rm -rf $cb_json
    if [ $errcode -eq 0 ]; then
        echo "Action pass"
    else
        echo "ERROR: Action fails. exit code: $errcode"
    fi
    exit $errcode
}

trap shell_exit SIGHUP SIGINT SIGTERM 0

###############################################################################
function node_in_cluster() {
    # http://docs.couchbase.com/couchbase-manual-2.5/cb-rest-api/#server-nodes-rest-api
    local node_ip=${1?}
    if curl --noproxy 127.0.0.1 -u "${cb_username}:${cb_passwd}" "http://${server_ip}:$cb_port/pools/default" 2>&1 | \
           grep "ns_1@$node_ip" 1>/dev/null 2>&1; then
        exit 0
    else
        exit 1
    fi
}

function add_node() {
    set -e
    # http://docs.couchbase.com/couchbase-manual-2.5/cb-rest-api/#adding-nodes-to-clusters
    #
    # curl -u $username:$password \
    # $server_ip:8091/controller/addNode \
    # -d "hostname=$client_ip&user=$username&password=$password"
    local node_ip=${1?}

    sleep_seconds=10
    output=$(curl --noproxy 127.0.0.1 -u "$cb_username:$cb_passwd" "$server_ip:$cb_port/controller/addNode" \
                  -d "hostname=$node_ip&user=$cb_username&password=$cb_passwd" 2>&1)
    # retry add_node, if it fails at the first time
    if ! ( echo -e "$output" | grep "otpNode.*ns" 1>/dev/null 2>&1); then
        echo "First run for adding node fails. msg: $output"
        echo "Retry to add new node"
        sleep "$sleep_seconds"
        output=$(curl --noproxy 127.0.0.1 -u "$cb_username:$cb_passwd" "$server_ip:$cb_port/controller/addNode" \
                      -d "hostname=$node_ip&user=$cb_username&password=$cb_passwd" 2>&1)
        if ! (echo -e "$output" | grep "otpNode.*ns" 1>/dev/null 2>&1); then
            echo "Error: fail to add node. msg: $output"
            exit 1
        fi
    fi
}

function rebalance_node() {
    set -e
    # http://docs.couchbase.com/couchbase-manual-2.5/cb-rest-api/#rebalancing-nodes
    #
    # curl -u $username:$password \
    # -d "ejectedNodes=&knownNodes=ns_1%40$server_ip%2Cns_1%40$client_ip" \
    # http://$server_ip:8091/controller/rebalance
    local node_ip=${1?}

    # get nodes
    curl --noproxy 127.0.0.1 -u "$cb_username:$cb_passwd" "http://$server_ip:$cb_port/pools/nodes" \
         2>/dev/null > "$cb_json"

    # TODO: error handling
    nodes=$(python -c "import sys, json
print(str(json.load(sys.stdin)['nodes']).replace(',', ',\n'))" < "$cb_json")
    node_list=$(echo "$nodes" | grep otpNode | sed -n "s/ u'otpNode': u'ns_1@\(.*\)',/\1/p")
    node_list_str=""
    for node in $node_list; do
        node_list_str="${node_list_str}ns_1@${node},"
    done
    node_list_str=${node_list_str%,}

    known_node_list=$(combine_node_list "$node_ip" "$node_list_str")
    # TODO check whether we can skip the action
    curl --noproxy 127.0.0.1 -v -u "$cb_username:$cb_passwd" \
         -X POST "http://$server_ip:$cb_port/controller/rebalance" \
         -d "ejectedNodes=&knownNodes=$known_node_list"
}

function combine_node_list() {
    local node_ip=${1?}
    local node_list_str=${2?}
    if [[ "${node_list_str}"  == *${node_ip}* ]]; then
        echo "$node_list_str"
    else
        echo "$node_list_str,ns_1@$node_ip"
    fi
}

###############################################################################

# bash -xe /opt/devops/bin/couchbase_cluster.sh node_in_cluster 172.17.1.70 172.17.1.71
action=${1?}
server_ip=${2?}
new_node_ip=${3?}
cb_username=${4:-"Administrator"}
cb_passwd=${5:-"password1234"}
cb_port=${6:-"8091"}

server_ip=$(gethostip -d "$server_ip")
new_node_ip=$(gethostip -d "$new_node_ip")

echo "$action server_ip: $server_ip, new_node_ip: $new_node_ip"
$action "$new_node_ip"
## File - couchbase_cluster.sh ends
