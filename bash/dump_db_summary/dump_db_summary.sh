#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
## https://raw.githubusercontent.com/DennyZhang/devops_public/2016-06-23/LICENSE
##
## File : dump_db_summary.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
## Sample:
## --
## Created : <2016-06-04>
## Updated: Time-stamp: <2016-06-24 09:03:42>
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
        echo "Call http://${server_ip}:${tcp_port}/pools/default/buckets"
        curl -u "${cb_username}:${cb_passwd}" "http://${server_ip}:${tcp_port}/pools/default/buckets" \
            | python -m json.tool > "$output_data_file"

        # parse json to get the summary
        output=$(python -c "import sys,json
list = json.load(sys.stdin)
list = map(lambda x: '%s: %s' % (x['name'], x['basicStats']), list)
print json.dumps(list)" < "$output_data_file")
        echo "$output" | python -m json.tool > "$output_data_file"
        # TODO: need to beautify json output
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
        echo "Call http://${server_ip}:${tcp_port}/_cat/shards?v"
        curl "http://${server_ip}:${tcp_port}/_cat/shards?v" \
             > "$output_data_file"
    fi
}

################################################################################
stdout_show_data_out=${1:-"false"}
cfg_dir=${2:-"/opt/devops/dump_db_summary/cfg_dir"}
data_out_dir=${3:-"/opt/devops/dump_db_summary/data_out"}
# support string/json
output_type=${4:-"json"}

[ -d "$cfg_dir" ] || mkdir -p "$cfg_dir"
[ -d "$data_out_dir" ] || mkdir -p "$data_out_dir"

cd "$cfg_dir"
for f in *.cfg; do
    if [ -f "$f" ]; then
        db_name=${f%%.cfg}
        # Sample: $cfg_dir/mongodb.cfg -> dump_mongodb_summary mongodb.cfg
        fun_name="dump_${db_name}_summary"
        command="$fun_name $f $output_type $data_out_dir/${db_name}.${output_type}"
        echo "Run function: $command"
        $command
    fi
done

if [ "$stdout_show_data_out" = "true" ]; then
    cd "$data_out_dir"
    for f in *.${output_type}; do
        if [ -f "$f" ]; then
            db_name=${f%%.*}
            echo "Dump $db_name data summary: $data_out_dir/$f"
            cat "$f"
        fi
    done
fi
## File: dump_db_summary.sh ends
