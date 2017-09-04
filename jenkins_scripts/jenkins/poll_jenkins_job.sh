#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : poll_jenkins_job.sh
## Author : DennyZhang.com <contact@dennyzhang.com>
## Description :
## --
## Created : <2015-06-02>
## Updated: Time-stamp: <2017-09-04 18:54:39>
##-------------------------------------------------------------------
jenkins_cli_jar=${1?}
jenkins_url=${2:-"http://localhost:18080/"}
jenkins_job=${3?}
max_wait_seconds=${4:-3600}

sleep_seconds=5

for((i=0; i<max_wait_seconds; i=i+sleep_seconds)); do {
    output=$(java -jar "$jenkins_cli_jar" -s "$jenkins_url" console "$jenkins_job" -n 10)
    echo "$output"

    if echo "$output" | grep 'Finished: FAILURE' 1>/dev/null 2>&1; then
        echo "Jenkins job failed: $jenkins_job"
        exit 1
    fi

    if echo "$output" | grep 'Finished: SUCCESS' 1>/dev/null 2>&1; then
        echo "Jenkins job success: $jenkins_job"
        exit 0
    fi

    echo "sleep $sleep_seconds"
    sleep $sleep_seconds
};
done

echo "Request timeout for $max_wait_seconds"
exit 1
## File : poll_jenkins_job.sh ends
