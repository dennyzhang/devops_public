#!/bin/bash -e
##-------------------------------------------------------------------
## File : rename_index_to_alias.sh
## Description : Rename an ES index to alias
##               1. Create a new index
##               2. Re-index the old index to new index
##               3. Remove the old index
##               4. Create a alias with the same name as old index name
##               5. Point the alias to the new index
## --
## Created : <2017-03-27>
## Updated: Time-stamp: <2017-06-18 21:37:02>
##-------------------------------------------------------------------
. library.sh

old_index_name=${1?}
new_index_name=${2:-""}
es_ip=${3:-""}
es_port=${4:-""}

target_alias_name="${old_index_name}"
log_file="/var/log/rename_index_to_alias_${BUILD_ID}.log"
# if $es_ip is not given, use ip of eth0 as default
if [ -z "$es_ip" ]; then
    es_ip=$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
fi

if [ -z "$new_index_name" ]; then
    new_index_name="${old_index_name}-new"
fi

if [ -z "$es_port" ]; then
    es_port="9200"
fi

if [ -z "$REINDEX_BATCH_SIZE" ]; then
    # By default _reindex uses scroll batches of 100. Here we change it to 500
    # https://www.elastic.co/guide/en/elasticsearch/reference/2.3/docs-reindex.html
    REINDEX_BATCH_SIZE="500"
fi

##-------------------------------------------------------------------
if [ "$(is_es_red "$es_ip" "$es_port")" = "yes" ]; then
    echo "ERROR: ES cluster is red"
    exit 1
fi

if [ "$(is_es_index_exists "$es_ip" "$es_port" "$old_index_name")" = "no" ]; then
    echo "ERROR: index($old_index_name) doesn't exist."
    exit 1
fi

if [ "$(is_es_alias_exists "$es_ip" "$es_port" "$target_alias_name")" = "yes" ]; then
    echo "ERROR: target alias($target_alias_name) already exist."
    exit 1
fi

##-------------------------------------------------------------------
log "Create index ($new_index_name) from old index($old_index_name)"
bash -ex ./create_index_from_old.sh "$old_index_name" "$new_index_name" "$es_port" "$es_ip"

log "Re-index the old index ($old_index_name) to new index($new_index_name)"

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

log "Close old index: ${old_index_name}"
curl -XPOST "http://${es_ip}:${es_port}/${old_index_name}/_close" | tee -a "$log_file"

log "Delete old index: ${old_index_name}"
curl -XDELETE "http://${es_ip}:${es_port}/${old_index_name}" | tee -a "$log_file"

log "Create alias using the name of ${old_index_name}"
time curl -XPOST "http://${es_ip}:${es_port}/_aliases" -d "
{
    \"actions\": [
    { \"add\": {
    \"alias\": \"${target_alias_name}\",
    \"index\": \"${new_index_name}\"
    }}
    ]
}" | tee -a "$log_file"

if tail -n 5 "$log_file" | grep "\"failures\" : \[ \]"; then
    log "keep going with the following process"
else
    log "ERROR to run previous curl command"
    tail -n 5 "$log_file"
    exit 1
fi

log "List alias of $target_alias_name"
curl -XGET "http://${es_ip}:${es_port}/_aliases?pretty" \
    | grep -C 10 "$target_alias_name"
## File : rename_index_to_alias.sh ends
