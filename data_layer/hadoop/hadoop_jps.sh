#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
## https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : hadoop_jps.sh
## Author : Denny <contact@dennyzhang.com>
## Description :
## --
## Created : <2016-06-04>
## Updated: Time-stamp: <2017-09-04 18:54:41>
##-------------------------------------------------------------------
user_list="hdfs yarn zookeeper mapred oozie hive hbase"
for hadoop_user in $user_list; do
    if grep "$hadoop_user" /etc/passwd 1>/dev/null 2>&1; then
        sudo -u "$hadoop_user" jps | grep -v Jps
    fi
done
## File : hadoop_jps.sh ends
