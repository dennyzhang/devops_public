#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : docker_helper.sh
## Author : Denny <contact@dennyzhang.com>
## Description :
## --
## Created : <2016-01-08>
## Updated: Time-stamp: <2017-09-04 18:54:42>
##-------------------------------------------------------------------
function guess_docker_daemon_ip() {
    local docker_daemon_ip=""
    local lists
    lists="172.18.42.1 172.17.42.1 172.18.0.1 172.17.0.1 192.168.50.10"
    lists=($lists)
    for ip in ${lists[*]}; do
        if ping -c3 "$ip" 2>/dev/null 1>/dev/null; then
            docker_daemon_ip=$ip
            break
        fi
    done
    echo "$docker_daemon_ip"
}

function install_docker() {
    local os_release_name
    if ! which docker 1>/dev/null 2>/dev/null; then
        os_release_name=$(os_release)
        if [ "$os_release_name" == "centos" ]; then
            log "yum install -y docker-io"
            yum install -y http://mirrors.yun-idc.com/epel/6/i386/epel-release-6-8.noarch.rpm
            yum install -y docker-io
            service docker start
            chkconfig docker on
        else
            log "Install docker: wget -qO- https://get.docker.com/ | sh"
            wget -qO- https://get.docker.com/ | sh
        fi
    else
        log "docker service exists, skip installation"
    fi
}

function create_enough_loop_device() {
    # When run docker in docker, docker daemon may fail to start, due to no enough loop device
    local file_count=${1:-50}
    # Docker start may fail, due to no available loopback devices
    for((i=0; i<file_count; i++)); do
        if [ ! -b /dev/loop$i ]; then
            echo "mknod -m0660 /dev/loop$i b 7 $i"
            mknod -m0660 /dev/loop$i b 7 $i
        fi
    done
}

function is_container_running(){
    local container_name=${1?}
    if docker ps -a | grep "$container_name" 1>/dev/null 2>/dev/null; then
        if docker ps | grep "$container_name" 1>/dev/null 2>/dev/null; then
            echo "running"
        else
            echo "dead"
        fi
    else
        echo "none"
    fi
}
######################################################################
## File : docker_helper.sh ends
