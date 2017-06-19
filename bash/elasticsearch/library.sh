#!/bin/bash -e
##-------------------------------------------------------------------
## File : library.sh
## Description :
## --
## Created : <2017-06-13>
## Updated: Time-stamp: <2017-06-18 21:38:56>
##-------------------------------------------------------------------
function is_es_red() {
    local es_ip=${1?}
    local es_port=${2?}
    if curl "$es_ip:$es_port/_cluster/health?pretty" | grep red 1>/dev/null 2>&1; then
        # add a sleep and try again. Sleep for 5 minutes
        sleep 300
        if curl "$es_ip:$es_port/_cluster/health?pretty" | grep red 1>/dev/null 2>&1; then
            echo "yes"
        else
            echo "no"
        fi
    else
        echo "no"
    fi
}

function is_es_index_exists() {
    local es_ip=${1?}
    local es_port=${2?}
    local index_name=${3?}
    if curl -I "$es_ip:$es_port/$index_name" \
            | grep "200 OK" 1>/dev/null 2>&1; then
        echo "yes"
    else
        echo "no"
    fi
}

function is_es_alias_exists() {
    local es_ip=${1?}
    local es_port=${2?}
    local alias_name=${3?}
    if curl -I "$es_ip:$es_port/_alias/$alias_name" \
            | grep "200 OK" 1>/dev/null 2>&1; then
        echo "yes"
    else
        echo "no"
    fi
}

function get_index_shard_count() {
    local es_ip=${1?}
    local es_port=${2?}
    local index_name=${3?}
    value=$(curl "$es_ip:$es_port/$index_name/_settings?pretty" | grep number_of_shards | awk -F':' '{print $2}')
    value=${value# \"}
    value=${value%\",}
    echo "$value"
}

function get_index_replica_count() {
    local es_ip=${1?}
    local es_port=${2?}
    local index_name=${3?}
    value=$(curl "$es_ip:$es_port/$index_name/_settings?pretty" | grep number_of_replicas | awk -F':' '{print $2}')
    value=${value# \"}
    value=${value%\",}
    echo "$value"
}

function log() {
    local msg=$*
    date_timestamp=$(date +['%Y-%m-%d %H:%M:%S'])
    echo -ne "$date_timestamp $msg\n"
    
    if [ -n "$LOG_FILE" ]; then
        echo -ne "$date_timestamp $msg\n" >> "$LOG_FILE"
    fi
}
## File : library.sh ends
