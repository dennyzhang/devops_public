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
## Updated: Time-stamp: <2016-06-12 10:25:44>
##-------------------------------------------------------------------
. /etc/profile

################################################################################
# Plugin Function
function dump_couchbase_summary() {
    local cfg_file=${1?}
    local output_type=${2?}
    local output_data_file=${3?}
    source "$cfg_file"
    # Get parameters from $cfg_file:
    #    server_ip, tcp_port, cb_username, cb_password
    if [ "$output_type" = "json" ]; then
        command="curl -u ${cb_username}:${cb_passwd} http://${server_ip}:${tcp_port}/pools/default/buckets"
        echo "Run command: $command"
        curl -u "${cb_username}:${cb_passwd}" "http://${server_ip}:${tcp_port}/pools/default/buckets" \
            | python -m json.tool > "$output_data_file"
        echo "TODO"
    fi
}

function dump_elasticsearch_summary() {
    local cfg_file=${1?}
    local output_type=${2?}
    local output_data_file=${3?}

    source "$cfg_file"
    # Get parameters from $cfg_file:
    #    server_ip, tcp_port
    if [ "$output_type" = "json" ]; then
        # TODO: Change to json
        command="curl http://${server_ip}:${tcp_port}/_cat/shards?v"
        echo "Run command: $command"
        curl "http://${server_ip}:${tcp_port}/_cat/shards?v" \
             > "$output_data_file"
        echo "TODO"
    fi
}

function dump_mongodb_summary() {
    local cfg_file=${1?}
    local output_type=${2?}
    local output_data_file=${3?}

    source "$cfg_file"
    if [ "$output_type" = "json" ]; then
        echo "TODO"
        echo "output_data_file: $output_data_file"
    fi
}

################################################################################
cfg_dir=${1:-"/opt/devops/dump_db_summary/cfg_dir"}
data_out_dir=${2:-"/opt/devops/dump_db_summary/data_out"}
# support string/json
output_type=${3:-"json"}

[ -d "$data_out_dir" ] || mkdir -p "$data_out_dir"

cd "$cfg_dir"
for f in *.cfg; do
    db_name=${f%%.cfg}
    # Sample: $cfg_dir/mongodb.cfg -> dump_mongodb_summary mongodb.cfg
    fun_name="dump_${db_name}_summary"
    command="$fun_name $f $output_type $data_out_dir/${db_name}.${output_type}"
    echo "Run function: $command"
    $command
done
## File: dump_db_summary.sh ends
