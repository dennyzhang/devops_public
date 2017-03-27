#!/bin/bash -e
##-------------------------------------------------------------------
## File : es_reindex.sh
## Description :
## --
## Created : <2017-03-27>
## Updated: Time-stamp: <2017-03-27 12:58:43>
##-------------------------------------------------------------------
old_index_name=${1?}
new_index_name=${2?}

shard_count=${3:-5}
replica_count=${4:-2}

es_ip="localhost"

echo "old_index_name: $old_index_name, new_index_name: $new_index_name"

echo "List all indices"
time curl -XGET "http://${es_ip}:9200/_cat/indices?v"

echo "create new index with proper shards and replicas"
time curl -XPUT "http://${es_ip}:9200/${new_index_name}?pretty" -d "
    {
       \"settings\" : {
       \"index\" : {
       \"number_of_shards\" : ${shard_count},
       \"number_of_replicas\" : ${replica_count}
       }
   }
}"

echo "Get the setting of the new index"
time curl -XGET "http://${es_ip}:9200/${new_index_name}/_settings?pretty"

echo "Reindex index. Attention: this will take a very long time, if the index is big"
time curl -XPOST "http://${es_ip}:9200/_reindex?pretty" -d "
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
time curl -XGET "http://${es_ip}:9200/_tasks?detailed=true&actions=*reindex&pretty"

alias_index_name=$(echo "$old_index_name" | sed 's/-index//g')
echo "Add index to existing alias and remove old index from that alias. alias: $alias_index_name"
time curl -XPOST "http://${es_ip}:9200/_aliases" -d "
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

# Close index
curl -XPOST "http://${es_ip}:9200/${old_index_name}/_close"

# Delete index
# curl -XDELETE "http://${es_ip}:9200/${old_index_name}?pretty"

## File : es_reindex.sh ends
