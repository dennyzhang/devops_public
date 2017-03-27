#!/bin/bash -e
##-------------------------------------------------------------------
## File : es_reindex.sh
## Description :
## --
## Created : <2017-03-27>
## Updated: Time-stamp: <2017-03-27 14:44:45>
##-------------------------------------------------------------------
old_index_name=${1?}
new_index_name=${2:-""}
alias_index_name=${3:-""}
shard_count=${4:-"5"}
replica_count=${5:-"1"}
es_ip=${6:-""}
es_port=${7:-"9200"}

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
# Sample test:
# export old_index_name="staging-index-46078234297e400a1648d9c427dc8c4b"
# export new_index_name="${old_index_name}-new"
# export alias_index_name=$(echo "$old_index_name" | sed 's/-index//g')
# export shard_count=5
# export replica_count=0
# export es_ip=$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
# export es_port=9200

echo "old_index_name: $old_index_name, new_index_name: $new_index_name"

echo "List all indices"
time curl -XGET "http://${es_ip}:${es_port}/_cat/indices?v"

echo "create new index with proper shards and replicas"
time curl -XPUT "http://${es_ip}:${es_port}/${new_index_name}?pretty" -d "
    {
       \"settings\" : {
       \"index\" : {
       \"number_of_shards\" : ${shard_count},
       \"number_of_replicas\" : ${replica_count}
       }
   }
}"

echo "Get the setting of the new index"
time curl -XGET "http://${es_ip}:${es_port}/${new_index_name}/_settings?pretty"

echo "Reindex index. Attention: this will take a very long time, if the index is big"
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
}"

# We can start a new terminal and check reindex status
echo "Get all re-index tasks"
time curl -XGET "http://${es_ip}:${es_port}/_tasks?detailed=true&actions=*reindex&pretty"

echo "Add index to existing alias and remove old index from that alias. alias: $alias_index_name"
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
}"

# List alias
curl -XPGET "http://${es_ip}:${es_port}/_aliases?pretty" | grep -C 10 "$(echo "$old_index_name" | sed "s/.*-index-//g")"

# Close index
curl -XPOST "http://${es_ip}:${es_port}/${old_index_name}/_close"

# Delete index
# curl -XDELETE "http://${es_ip}:${es_port}/${old_index_name}?pretty"

echo "List all indices"
time curl -XGET "http://${es_ip}:${es_port}/_cat/indices?v"

## File : es_reindex.sh ends
