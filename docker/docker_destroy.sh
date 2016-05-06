#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : docker_destroy.sh
## Author : DennyZhang.com <denny@dennyzhang.com>
## Description :
## --
## Created : <2016-01-02>
## Updated: Time-stamp: <2016-04-26 22:55:43>
##-------------------------------------------------------------------
if ! which docker 2>/dev/null 1>/dev/null; then
    echo "Skip, since docker is not installed"
else
    if ! sudo service docker status 2>/dev/null 1>/dev/null; then
        echo "Start docker daemon"
        sudo service docker start
    fi

    echo "Prepare to destroy all docker contianers"
    for container in $(sudo docker ps -a | grep -v '^CONTAINER' | awk -F' ' '{print $1}'); do
        echo "docker inspect $container"
        sudo docker inspect "$container"

        echo "Destroy container: $container."
        sudo docker stop "$container" || true
        sudo docker rm "$container" || true
    done

    echo "shutdown docker daemon"
    sudo service docker stop
fi
## File : docker_destroy.sh ends
