#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
## https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : mapreduce_example.sh
## Author : Denny <contact@dennyzhang.com>
## Description :
## --
## Created : <2016-06-04>
## Updated: Time-stamp: <2017-09-04 18:54:40>
##-------------------------------------------------------------------
function log() {
    local msg=$*
    date_timestamp=$(date +['%Y-%m-%d %H:%M:%S'])
    echo -ne "$date_timestamp $msg\n"
    
    if [ -n "$LOG_FILE" ]; then
        echo -ne "$date_timestamp $msg\n" >> "$LOG_FILE"
    fi
}

mapreduce_sample_jar="/usr/hdp/2.3.4.7-4/hadoop-mapreduce/hadoop-mapreduce-examples-2.7.1.2.3.4.7-4.jar"
output_id="output_$$_$(date +'%Y-%m-%d_%H-%M-%S')"
log "Clean up directories: hdfs:/user/hdfs/test/input"
su -s /bin/bash hdfs -c "hdfs dfs -rm -r /user/hdfs/test/input" || true

log "Make source directory in hdfs: mkdir -p /user/hdfs/test/input"
su -s /bin/bash hdfs -c "hdfs dfs -mkdir -p /user/hdfs/test/input"

log "Data input: /etc/hadoop/conf"
su -s /bin/bash hdfs -c "hdfs dfs -put /etc/hadoop/conf /user/hdfs/test/input"

log "List data: hdfs:/user/hdfs/test/input/"
su -s /bin/bash hdfs -c "hdfs dfs -ls /user/hdfs/test/input"

# run mapr job
su -s /bin/bash hdfs -c "yarn jar $mapreduce_sample_jar grep /user/hdfs/test/input/conf $output_id 'dfs[a-z.]+'"

rm -rf /tmp/output/

# get output
su -s /bin/bash hdfs -c "hdfs dfs -get $output_id /tmp/output"

log "Show result"
cat /tmp/output/*

log "Sample MapReduce Test pass"
## File : mapreduce_example.sh ends
