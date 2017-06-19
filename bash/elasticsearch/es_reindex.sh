#!/bin/bash -e
##-------------------------------------------------------------------
## File : es_reindex.sh
## Description : Re-index existing giant index to create more shards.
## Then create alias to handle the requests properly
## Check more: https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-reindex.html
##
## --
## Created : <2017-03-27>
## Updated: Time-stamp: <2017-06-17 11:55:53>
##-------------------------------------------------------------------
. library.sh
old_index_name=${1?}
new_index_name=${2?}
index_alias_name=${3?}
es_port=${4?}
whether_update_alias=${5:-"no"}
es_ip=${6:-""}

if [ -z "$REINDEX_BATCH_SIZE" ]; then
    # By default _reindex uses scroll batches of 100. Here we change it to 500
    # https://www.elastic.co/guide/en/elasticsearch/reference/2.3/docs-reindex.html
    REINDEX_BATCH_SIZE="500"
fi

log_file="/var/log/es_reindex_sh_${BUILD_ID}.log"
##-------------------------------------------------------------------
# if $es_ip is not given, use ip of eth0 as default
if [ -z "$es_ip" ]; then
    es_ip=$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
fi

##-------------------------------------------------------------------
# Precheck
if [ "$index_alias_name" = "$old_index_name" ]; then
    echo "ERROR: wrong parameter. old_index_name and index_alias_name can't be the same" | tee -a "$log_file"
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

if [ "$(is_es_index_exists "$es_ip" "$es_port" "$new_index_name")" = "no" ]; then
    echo "ERROR: new index($new_index_name) doesn't exist."
    exit 1
fi
##-------------------------------------------------------------------

log "List all indices"
curl -XGET "http://${es_ip}:${es_port}/_cat/indices?v"

# TODO: better way to make sure all shards(primary/replica) for this new index are good.

if [ "$(curl "$es_ip:$es_port/_cat/shards?v" | grep "${new_index_name}" | grep -c -v STARTED)" = "0" ]; then
    log "index(${new_index_name}) is up and running"
else
    log "index(${new_index_name}) is not up and running"
    exit 1
fi

log "Reindex index. Attention: this will take a very long time, if the index is big"
time curl -XPOST "http://${es_ip}:${es_port}/_reindex?pretty" -d "
 {
 \"conflicts\": \"proceed\",
 \"source\": {
 \"index\": \"${old_index_name}\",
 \"size\": \"${REINDEX_BATCH_SIZE}\"
 },
 \"dest\": {
 \"index\": \"${new_index_name}\",
 \"op_type\": \"create\"
 }
 }" | tee -a "$log_file"

# confirm status, before proceed
if tail -n 5 "$log_file" | grep "\"failures\" : \[ \]"; then
    log "keep going with the following process"
else
    log "ERROR to run previous curl command"
    tail -n 5 "$log_file"
    exit 1
fi

# # We can start a new terminal and check reindex status
# log "Get all re-index tasks"
# time curl -XGET "http://${es_ip}:${es_port}/_tasks?detailed=true&actions=*reindex&pretty"

# # Check status
# time curl -XGET "http://${es_ip}:${es_port}/_cat/indices?v"

if [ "$whether_update_alias" = "yes" ]; then
    log "Add index to existing alias and remove old index from that alias. alias: $index_alias_name"
    time curl -XPOST "http://${es_ip}:${es_port}/_aliases" -d "
{
 \"actions\": [
 { \"remove\": {
 \"alias\": \"${index_alias_name}\",
 \"index\": \"${old_index_name}\"
 }},
 { \"add\": {
 \"alias\": \"${index_alias_name}\",
 \"index\": \"${new_index_name}\"
 }}
 ]
}" | tee -a "$log_file"

    echo >> "$log_file"

    if tail -n 1 "$log_file" | grep "\"acknowledged\"*:*true"; then
        log "keep going with the following process"
    else
        log "ERROR to create alias"
        tail -n 5 "$log_file"
        exit 1
    fi

    # Close index: only after no requests access old index, we can close it
    curl -XPOST "http://${es_ip}:${es_port}/${old_index_name}/_close" | tee -a "$log_file"
fi

log "List all alias"
curl -XGET "http://${es_ip}:${es_port}/_aliases?pretty" \
    | grep -C 10 "$(echo "$old_index_name" | sed "s/.*-index-//g")" | tee -a "$log_file"

# Delete index
# curl -XDELETE "http://${es_ip}:${es_port}/${old_index_name}?pretty" | tee -a "$log_file"

log "List all indices"
curl -XGET "http://${es_ip}:${es_port}/_cat/indices?v"
## File : es_reindex.sh ends
