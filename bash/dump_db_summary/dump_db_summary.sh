#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
## https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : dump_db_summary.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
## Sample:
## --
## Created : <2016-06-04>
## Updated: Time-stamp: <2016-06-12 10:14:31>
##-------------------------------------------------------------------
. /etc/profile

################################################################################
# Plugin Function
function dump_couchbase_summary() {
    local cfg_file=${1?}
    local output_type=${2?}
    source "$cfg_file"
    # Get parameters from $cfg_file:
    #    server_ip, tcp_port, cb_username, cb_password
    if [ "$output_type" = "json" ]; then
        command="curl -u ${cb_username}:${cb_passwd} http://${server_ip}:${tcp_port}/pools/default/buckets"
        command="$command | python -m json.tool"
        echo "TODO"
    fi
}

function dump_elasticsearch_summary() {
    local cfg_file=${1?}
    local output_type=${2?}
    source "$cfg_file"
    # Get parameters from $cfg_file:
    #    server_ip, tcp_port
    if [ "$output_type" = "json" ]; then
        curl "http://${server_ip}:${tcp_port}/_cat/shards?v"
        echo "TODO"
    fi
}

function dump_mongodb_summary() {
    local cfg_file=${1?}
    local output_type=${2?}
    source "$cfg_file"
    if [ "$output_type" = "json" ]; then
        echo "TODO"
    fi
}
################################################################################
cfg_dir=${1:-"/opt/devops/dump_db_summary/cfg_dir"}
# support string/json
output_type=${2:-"json"}

cd "$cfg_dir"
for f in *.cfg; do
    db_name=${f%%.cfg}
    # Sample: $cfg_dir/mongodb.cfg -> dump_mongodb_summary mongodb.cfg
    fun_name="dump_${db_name}_summary"
    command="$fun_name $f $output_type"
    echo "$command"
    $command
done
## File: dump_db_summary.sh ends
