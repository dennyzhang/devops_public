#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
## https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : hdfs_createdir.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
## --
## Created : <2016-06-04>
## Updated: Time-stamp: <2016-06-23 16:00:09>
##-------------------------------------------------------------------
flagfile=${1?}
shift
dir_to_create=$*

if [ -f "$flagfile" ]; then
    log "Error: $flagfile exists, which indicates it's already initialized"
    exit 1
fi

hadoop_user="hdfs"
# create folders for hadoop-mapreduce-historyserver
for dir in $dir_to_create; do
    su -s /bin/bash "$hadoop_user" -c "hdfs dfs -mkdir -p ${dir}"
    su -s /bin/bash "$hadoop_user" -c "hdfs dfs -chmod -R 777 ${dir}"
done

touch "$flagfile"
## File : hdfs_createdir.sh ends
