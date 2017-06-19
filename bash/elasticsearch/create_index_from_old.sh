#!/bin/bash -e
##-------------------------------------------------------------------
## File : create_index_from_old.sh
## Description : Re-index existing giant index to create more shards.
## Then create alias to handle the requests properly
## Check more: https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-reindex.html
##
## --
## Created : <2017-03-27>
## Updated: Time-stamp: <2017-06-17 13:26:09>
##-------------------------------------------------------------------
. library.sh

old_index_name=${1?}
new_index_name=${2?}
es_port=${3?}
es_ip=${4:-""}
shard_count=${5:-""}
replica_count=${6:-""}

log_file="/var/log/create_index_from_old_${BUILD_ID}.log"
# if $es_ip is not given, use ip of eth0 as default
if [ -z "$es_ip" ]; then
    es_ip=$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
fi

##-------------------------------------------------------------------
# Precheck
if [ "$index_alias_name" = "$old_index_name" ]; then
    echo "ERROR: wrong parameter. old_index_name and index_alias_name can't be the same"
    exit 1
fi

# TODO: quit when alias and index doesn't match

if [ "$(is_es_red "$es_ip" "$es_port")" = "yes" ]; then
    echo "ERROR: ES cluster is red"
    exit 1
fi

if [ "$(is_es_index_exists "$es_ip" "$es_port" "$old_index_name")" = "no" ]; then
    echo "ERROR: old index($old_index_name) doesn't exist."
    exit 1
fi

if [ "$(is_es_index_exists "$es_ip" "$es_port" "$new_index_name")" = "yes" ]; then
    echo "ERROR: new index($new_index_name) already exist."
    exit 1
fi

if [ -z "$shard_count" ]; then
    shard_count=$(get_index_shard_count "$es_ip" "$es_port" "$old_index_name")
fi

if [ -z "$replica_count" ]; then
    replica_count=$(get_index_replica_count "$es_ip" "$es_port" "$old_index_name")
fi

if ! which jq 1>/dev/null 2>&1; then
    echo "ERROR: jq is not installed"
    exit 1
else
    if ! jq --version | grep "jq-1.5"; then
        echo "ERROR: Only jq-1.5 has been verified. Please make sure you have the right version installed"
        exit 1
    fi
fi

##-------------------------------------------------------------------
log "old_index_name: $old_index_name, new_index_name: $new_index_name"

log "List all indices"
curl -XGET "http://${es_ip}:${es_port}/_cat/indices?v"

tmp_dir="/tmp/${old_index_name}"
[ -d "$tmp_dir" ] || mkdir -p "$tmp_dir"

log "Get setting and mappings of old index to ${tmp_dir}/create.json"

curl "http://${es_ip}:${es_port}/${old_index_name}/_settings" | \
    jq ".[] | .settings.index.number_of_shards=\"${shard_count}\" | .settings.index.number_of_replicas=\"${replica_count}\"" \
       > "${tmp_dir}/settings.json"

curl "http://${es_ip}:${es_port}/${old_index_name}/_mapping" \
    | jq '.[]' > "${tmp_dir}/mapping.json"

cat "${tmp_dir}/mapping.json" "${tmp_dir}/settings.json" \
    | jq --slurp '.[0] * .[1]' > "${tmp_dir}/create.json"

create_timeout="30m"
log "create new index with settings and mappings"
time curl -XPOST "http://${es_ip}:${es_port}/${new_index_name}?timeout=${create_timeout}&wait_for_active_shards=all" \
     -d @"${tmp_dir}/create.json" | tee -a "$log_file"
echo >> "$log_file"

if tail -n 1 "$log_file" | grep "\"acknowledged\"*:*true"; then
    log "keep going with the following process"
else
    log "ERROR to run previous curl command"
    tail -n 5 "$log_file"
    exit 1
fi

log "Get the setting of the new index"
curl -XGET "http://${es_ip}:${es_port}/${new_index_name}/_settings?pretty"
## File : create_index_from_old.sh ends
