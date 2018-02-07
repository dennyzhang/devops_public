#!/bin/bash -e
################################################################################################
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : stop_old_containers.sh
## Author: doungni
## Co-Author : Denny <contact@dennyzhang.com>
## Description : Stop old long-run docker containers, to save OS resource
## --
## Created : <2015-12-03>
## Updated: Time-stamp: <2017-09-04 18:54:39>
##-------------------------------------------------------------------
################################################################################################
# * By Jenkins config
#       keep_days : Over a given period of time will be stop
#       docker_ip_port: Docker daemon server ip:port
#       regular_white_list: Regular expressions are supported
# * By define parameter
#       ssh_identity_file ssh_connet white_list running_contianer_names
#       stop_container_list flag count_v container_name container_start_sd
#       container_start_ts server_current_ts
################################################################################################
. /etc/profile
[ -n "$DOWNLOAD_TAG_NAME" ] || export DOWNLOAD_TAG_NAME="tag_v6"
export DOWNLOAD_PREFIX="https://raw.githubusercontent.com/DennyZhang/devops_public/${DOWNLOAD_TAG_NAME}"
if [ ! -f /var/lib/devops/refresh_common_library.sh ]; then
    [ -d /var/lib/devops/ ] || (sudo mkdir -p /var/lib/devops/ && sudo chmod 777 /var/lib/devops)
    wget -O /var/lib/devops/refresh_common_library.sh "$DOWNLOAD_PREFIX/common_library/refresh_common_library.sh"
    chmod 777 /var/lib/devops/refresh_common_library.sh
fi
bash /var/lib/devops/refresh_common_library.sh "3536991806" "/var/lib/devops/devops_common_library.sh" \
     "${DOWNLOAD_PREFIX}/common_library/devops_common_library.sh"
. /var/lib/devops/devops_common_library.sh
################################################################################################
# TODO: Code quality of this file is low, need to refine or even re-write

# Docker client version should newer than 1.7.1
function stop_expired_container() {
    # Save running container names
    running_container_names=($($ssh_connect docker ps | awk '{print $NF}' | sed '1d'))
    log "Docker daemon: $daemon_ip:$daemon_port current running container list[${#running_container_names[@]}]:\n${running_container_names[*]}"

    # Continue to traverse the currently running container on the server
    for container_name in "${running_container_names[@]}"; do
        # parameter: container_start_sd, container_start_ts server_current_ts only used in the Docker version 1.9.1
        # time format:standard -> sd, timestamp -> ts; use: "docker inspect -f"-format the output using the given go template
        container_start_sd=$($ssh_connect docker inspect -f '{{.State.StartedAt}}' "$container_name")
        container_start_ts=$($ssh_connect date +%s -d "$container_start_sd")

        # get remote server current timestamp
        server_current_ts=$($ssh_connect date +%s)

        # 1day =24h =1440min =86400s
        if [ $((server_current_ts-container_start_ts)) -lt $((keep_days*86400)) ]; then
            continue
        fi

        # Count value
        local count_v=0
        local flag=0
        if [ ${#white_list[@]} -gt 0 ]; then
            # Mark variable
            for white_name in "${white_list[@]}"; do
                # Find the container in the white list and mark it as 1
                if [ "$container_name" = "$white_name" ]; then
                    flag=1
                    break
                fi
            done
        fi

        if [ $flag -eq 0 ]; then
           log "Stop Container: [$container_name]"
           $ssh_connect docker stop "$container_name"

           # Store is not white list and the need to stop the container
           stop_container[$count_v]=$container_name
           count_v=$((count_v+1))
       fi
    done
}
############################## Shell Start #####################################################
ssh_identity_file="$HOME/.ssh/id_rsa"
ensure_variable_isset "docker_ip_port parameter must be set" "$docker_ip_port"

# Jenkins parameter judge
if [ "$keep_days" -lt 0 ]; then
    log "ERROR: $keep_days must be greater than or equal to 0"
    exit 1
fi

docker_ip_port=(${docker_ip_port// / })
if [ -n "$regular_white_list" ]; then
    regular_white_list=(${regular_white_list// / })
else
    log "Regular white list is empty, will stop over than $keep_days all containers"
fi

for ip_port in "${docker_ip_port[@]}"; do
    daemon_ip_port=(${ip_port//:/ })
    daemon_ip=${daemon_ip_port[0]}
    daemon_port=${daemon_ip_port[1]}

    # Server Ip:Port connect judge
    nc_return=$(nc -w 1 "$daemon_ip" "$daemon_port" 1>/dev/null 2>&1 && echo yes || echo no)
    if [ "x$nc_return" == "xno" ]; then
        log "Error: Can not connect docker daemon server $daemon_ip:$daemon_port"
        exit 1
    fi

    # SSH connect parameter
    ssh_connect="ssh -p $daemon_port -i $ssh_identity_file -o StrictHostKeyChecking=no root@$daemon_ip"

    if [ ${#regular_white_list[@]} -gt 0 ]; then
        for regular in "${regular_white_list[@]}"; do
            regular_list=($($ssh_connect docker ps | awk '{print $NF}' | sed '1d' | grep -e "^$regular"))||true
            white_list+=("${regular_list[@]}")
        done

        log "Docker daemon $daemon_ip:$daemon_port white list[${#white_list[@]}]:\n${white_list[*]}"
    fi

    # Call stop expired container function
    stop_expired_container

    log "Docker daemon server: $daemon_ip:$daemon_port operation is completed!"
    stop_container_list+=("\n${daemon_ip}:${daemon_port} stop container list:\n${stop_container[@]}")

    # Empty current ip:port white list
    unset 'white_list[@]'
done

if [ ${#stop_container[@]} -gt 0 ]; then
    log "${stop_container_list[@]}"
    exit 1
else
    log "Did not stop any containers"
fi
############################## Shell End #######################################################
