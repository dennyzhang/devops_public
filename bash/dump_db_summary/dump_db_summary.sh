#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
## https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : dump_db_summary.sh
## Author : Denny <contact@dennyzhang.com>
## Description :
## Sample:
##          /opt/devops/dump_db_summary/cfg_dir/couchbase.cfg -> dump_couchbase_summary
##             export server_ip=192.168.0.3
##             export tcp_port=8091
##             export cb_username=Administrator
##             export cb_passwd=MyDBPassword1
##
##          /opt/devops/dump_db_summary/cfg_dir/elasticsearch.cfg -> dump_elasticsearch_summary
##             export server_ip=192.168.0.4
##             export tcp_port=9200
## --
## Created : <2016-06-04>
## Updated: Time-stamp: <2016-07-15 14:26:11>
##-------------------------------------------------------------------
. /etc/profile

################################################################################
# Plugin Function
function dump_couchbase_summary() {
    local cfg_file=${1?}
    local output_file_prefix=${2?}

    logstash_postfix="_logstash.txt"
    stdout_output_file="${output_file_prefix}.out"
    source "$cfg_file"

    tmp_data_file="/tmp/dump_couchbase_$$.log"
    # Get parameters from $cfg_file:
    #    server_ip, tcp_port, cb_username, cb_password
    echo "Call http://${server_ip}:${tcp_port}/pools/default/buckets"
    curl -u "${cb_username}:${cb_passwd}" "http://${server_ip}:${tcp_port}/pools/default/buckets" \
        | python -m json.tool > "$tmp_data_file"

    # parse json to get the summary
    output=$(python -c "import sys,json
list = json.load(sys.stdin)
print 'bucket\tdiskUsed\tmemUsed\tdiskFetches\tquotaPercentUsed\topsPerSec\tdataUsed\titemCount'
list = map(lambda x: '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' % (str(x['name']), str(x['basicStats']['diskUsed']), str(x['basicStats']['memUsed']), str(x['basicStats']['diskFetches']), str(x['basicStats']['quotaPercentUsed']), str(x['basicStats']['opsPerSec']), str(x['basicStats']['dataUsed']), str(x['basicStats']['itemCount'])), list)
print '\n'.join(list)" < "$tmp_data_file")
    # TODO: need to remove this file, even if exceptions happen
    rm -rf "$tmp_data_file"
    echo "$output" > "$stdout_output_file"

    # output columns: bucket diskUsed memUsed diskFetches quotaPercentUsed opsPerSec dataUsed itemCount
    IFS=$'\n'
    grep -v "^bucket"  < "$stdout_output_file" | while IFS= read -r line
    do
        unset IFS
        item_name=$(echo "$line" | awk -F"\t" '{print $1}')
        prop_value=$(echo "$line" | awk -F"\t" '{print $8}')
        # sample output: echo "[11/Jul/2016:14:10:45 +0000] bucket1 CBItemNum 20" >> /var/log/data_report.log
        insert_elk_entry "$item_name" "CBItemNum" "$prop_value" "${output_file_prefix}${logstash_postfix}"
    done
}

function dump_elasticsearch_summary() {
    local cfg_file=${1?}
    local output_file_prefix=${2?}

    logstash_postfix="_logstash.txt"
    stdout_output_file="${output_file_prefix}.out"
    source "$cfg_file"

    # Get parameters from $cfg_file: server_ip, tcp_port
    echo "Call http://${server_ip}:${tcp_port}/_cat/shards?v"
    curl "http://${server_ip}:${tcp_port}/_cat/shards?v" > "$stdout_output_file"

    # output columns: index shard prirep state docs store ip node
    IFS=$'\n'
    grep -v "^index " < "$stdout_output_file" | grep "  p  " | while IFS= read -r line
    do
        unset IFS
        item_name=$(echo "$line" | awk -F' ' '{print $1}')
        prop_value=$(echo "$line" | awk -F' ' '{print $5}')
        # store=$(echo "$line" | awk -F' ' '{print $6}')
        # sample output: echo "[11/Jul/2016:14:10:45 +0000] master-index-8cd6e43115 ESItemNum 200" >> /var/log/data_report.log
        insert_elk_entry "$item_name" "ESItemNum" "$prop_value" "${output_file_prefix}${logstash_postfix}"
    done
}

function insert_elk_entry() {
    local item_name=${1?}
    local property_name=${2?}
    local property_value=${3?}
    local data_file=${4?}

    LANG=en_US
    datetime_utc=$(date -u +['%d/%h/%Y:%H:%M:%S +0000'])
    echo "$datetime_utc $item_name $property_name $property_value" >> "$data_file"
}

################################################################################
stdout_show_data_out=${1:-"false"}
cfg_dir=${2:-"/opt/devops/dump_db_summary/cfg_dir"}
data_out_dir=${3:-"/opt/devops/dump_db_summary/data_out"}

[ -d "$cfg_dir" ] || mkdir -p "$cfg_dir"
[ -d "$data_out_dir" ] || mkdir -p "$data_out_dir"

cd "$cfg_dir"
for f in *.cfg; do
    if [ -f "$f" ]; then
        db_name=${f%%.cfg}
        fun_name="dump_${db_name}_summary"
        command="$fun_name $f $data_out_dir/${db_name}"
        echo "Run function: $command"
        "dump_${db_name}_summary" "$f" "$data_out_dir/${db_name}"
    fi
done

if [ "$stdout_show_data_out" = "true" ]; then
    cd "$data_out_dir"
    for f in *.out; do
        if [ -f "$f" ]; then
            db_name=${f%%.*}
            echo "Dump $db_name data summary: $data_out_dir/$f"
            cat "$f"
        fi
    done
fi
## File: dump_db_summary.sh ends
