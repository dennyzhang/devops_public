#!/bin/bash -x
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : wait_jenkins_up.sh
## Author : DennyZhang.com <contact@dennyzhang.com>
## Description :
## --
## Created : <2015-06-02>
## Updated: Time-stamp: <2017-09-04 18:54:38>
##-------------------------------------------------------------------
jenkins_url=${1:-"http://127.0.0.1:28080/jnlpJars/jenkins-cli.jar/"}
max_wait_seconds=${2:-600}

sleep_seconds=5

for((i=0; i<max_wait_seconds; i=i+sleep_seconds)); do {
    output=$(curl --noproxy 127.0.0.1 -I "$jenkins_url")

    if echo "$output" | grep 'HTTP/1.1 200 OK' 1>/dev/null 2>&1; then
        echo "Jenkins is up"
        exit 0
    fi

    echo "sleep $sleep_seconds"
    sleep "$sleep_seconds"
};
done

echo "Request timeout for $max_wait_seconds"
exit 1
## File : wait_jenkins_up.sh ends
