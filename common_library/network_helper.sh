#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : network_helper.sh
## Author : Denny <contact@dennyzhang.com>
## Description :
## --
## Created : <2016-01-08>
## Updated: Time-stamp: <2017-09-04 18:54:41>
##-------------------------------------------------------------------
function is_port_listening() {
    local port=${1?}
    lsof -i "tcp:${port}" | grep LISTEN 1>/dev/null
}

function check_ssh_available() {
    # Sample: if [ "x$(check_ssh_available $server_ip $server_port)" = "xyes" ] ...
    local server_ip=${1?}
    local server_port=${2?}
    nc -w 1 "$server_ip" "$server_port" 1>/dev/null 2>&1 && echo yes || echo no
}

function check_url_200() {
    local url=${1?}
    if curl -I "$url" | grep "HTTP/1.* 200 OK" 2>/dev/null 1>/dev/null; then
        echo "yes"
    else
        echo "no"
    fi
}

function check_network() {
    # TODO: improve code quality

    local max_retries_count=${1:-3}
    local website_list=${2:-"https://bitbucket.org/"}
    local timeout=7
    local maxtime=10
    local sleep_time=5
    local check_flag=true

    log "max_retries_count=$max_retries_count, website_list=$website_list"
    connect_failed_website=""
    for website in ${website_list[*]}; do
        for ((i=1; i <=max_retries_count; i++)); do
            # get http_code
            curl -I -s --connect-timeout $timeout -m $maxtime "$website" | tee website_tmp.txt
            ret=$(grep "200 OK" website_tmp.txt && echo yes || echo no)
            if [ "X$ret" = "Xyes" ]; then
                log "$website connect succeed"
                break
            fi
            if [ "$i" = "$max_retries_count" ];then
                log "$website connect failed"
                log "The curl result:"
                cat website_tmp.txt
                connect_failed_website="${connect_failed_website} ${website}"
                check_flag=false
                break
            fi
            sleep $sleep_time
        done
    done
    log "========== connect_failed_website= ${connect_failed_website}=========="
    if ! $check_flag ;then
        exit 1
    fi
}
######################################################################
## File : network_helper.sh ends
