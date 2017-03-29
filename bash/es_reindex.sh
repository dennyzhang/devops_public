#!/bin/bash -e
##-------------------------------------------------------------------
## File : es_reindex.sh
## Description : Re-index existing giant index to create more shards.
##               Then create alias to handle the requests properly
##               Check more: https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-reindex.html
## --
## Created : <2017-03-27>
## Updated: Time-stamp: <2017-03-29 13:14:26>
##-------------------------------------------------------------------
old_index_name=${1?}
shard_count=${2:-"10"}
alias_index_name=${3:-""}
new_index_name=${4:-""}
replica_count=${5:-"2"}
es_ip=${6:-""}
es_port=${7:-"9200"}

log_file="/var/log/es_reindex.log"
##-------------------------------------------------------------------
# Configure default value, if not given
if [ -z "$alias_index_name" ]; then
    # Note ES alias may not be like this
    alias_index_name=$(echo "$old_index_name" | sed 's/-index//g')
fi

if [ -z "$new_index_name" ]; then
    new_index_name="${old_index_name}-new"
fi

# if $es_ip is not given, use ip of eth0 as default
if [ -z "$es_ip" ]; then
    es_ip=$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
fi

##-------------------------------------------------------------------
# Precheck
if [ "$alias_index_name" = "$old_index_name" ]; then
    echo "ERROR: wrong parameter. old_index_name and alias_index_name can't be the same" >> "$log_file"
    exit 1
fi

# TODO: quit when alias and index doesn't match

# TODO: quit when curl fails
##-------------------------------------------------------------------
# Sample test:
# export old_index_name="staging-index-46078234297e400a1648d9c427dc8c4b"
# export new_index_name="${old_index_name}-new"
# export alias_index_name=$(echo "$old_index_name" | sed 's/-index//g')
# export shard_count=5
# export replica_count=0
# export es_ip=$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
# export es_port=9200

echo "$(date +['%Y-%m-%d %H:%M:%S']) old_index_name: $old_index_name, new_index_name: $new_index_name" >> "$log_file"

echo "$(date +['%Y-%m-%d %H:%M:%S']) List all indices" >> "$log_file"
time curl -XGET "http://${es_ip}:${es_port}/_cat/indices?v" | tee -a "$log_file"

# TODO: verify whether ES index exists

echo "$(date +['%Y-%m-%d %H:%M:%S']) create new index with proper shards and replicas" >> "$log_file"
time curl -XPUT "http://${es_ip}:${es_port}/${new_index_name}?pretty" -d "
    {
       \"settings\" : {
       \"index\" : {
       \"number_of_shards\" : ${shard_count},
       \"number_of_replicas\" : ${replica_count}
       }
   }
}" | tee -a "$log_file"

echo "$(date +['%Y-%m-%d %H:%M:%S']) Get the setting of the new index" >> "$log_file"
time curl -XGET "http://${es_ip}:${es_port}/${new_index_name}/_settings?pretty" | tee -a "$log_file"

# TODO: make sure all shards(primary/replica) for this new index are good.

echo "$(date +['%Y-%m-%d %H:%M:%S']) Reindex index. Attention: this will take a very long time, if the index is big" >> "$log_file"
time curl -XPOST "http://${es_ip}:${es_port}/_reindex?pretty" -d "
    {
    \"conflicts\": \"proceed\",
    \"source\": {
    \"index\": \"${old_index_name}\"
    },
    \"dest\": {
    \"index\": \"${new_index_name}\",
    \"op_type\": \"create\"
    }
}" | tee -a "$log_file"

# TODO: confirm status, before proceed

# We can start a new terminal and check reindex status
echo "$(date +['%Y-%m-%d %H:%M:%S']) Get all re-index tasks" >> "$log_file"
time curl -XGET "http://${es_ip}:${es_port}/_tasks?detailed=true&actions=*reindex&pretty" | tee -a "$log_file"

# TODO: don't add alias

echo "$(date +['%Y-%m-%d %H:%M:%S']) Add index to existing alias and remove old index from that alias. alias: $alias_index_name" >> "$log_file"
time curl -XPOST "http://${es_ip}:${es_port}/_aliases" -d "
{
    \"actions\": [
    { \"remove\": {
    \"alias\": \"${alias_index_name}\",
    \"index\": \"${old_index_name}\"
    }},
    { \"add\": {
    \"alias\": \"${alias_index_name}\",
    \"index\": \"${new_index_name}\"
    }}
    ]
}" | tee -a "$log_file"

# echo "$(date +['%Y-%m-%d %H:%M:%S']) List all alias" >> "$log_file"
# curl -XGET "http://${es_ip}:${es_port}/_aliases?pretty" \
#       | grep -C 10 "$(echo "$old_index_name" | sed "s/.*-index-//g")" | tee -a "$log_file"

# Close index: only after no requests access old index, we can close it
# curl -XPOST "http://${es_ip}:${es_port}/${old_index_name}/_close" | tee -a "$log_file"

# Delete index
# curl -XDELETE "http://${es_ip}:${es_port}/${old_index_name}?pretty" | tee -a "$log_file"

echo "$(date +['%Y-%m-%d %H:%M:%S']) List all indices" >> "$log_file"
time curl -XGET "http://${es_ip}:${es_port}/_cat/indices?v" | tee -a "$log_file"
## File : es_reindex.sh ends
