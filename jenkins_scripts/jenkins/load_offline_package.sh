#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : load_offline_package.sh
## Author : Manley <daywbdb@qq.com>
## Co-Author : UU <youyou.li78@gmail.com>
## Description :
## --
## Created : <2016-01-06>
## Updated: Time-stamp: <2017-06-28 18:50:12>
##-------------------------------------------------------------------

################################################################################################
## env variables:
##       from_server: 172.17.0.2:22
##       to_server_list: 172.17.0.2:4022
##                       172.17.0.2:6022
##       package_location: /root/install_file/XXX.tar.gz
##       package_new_location: /var/www/repo/download
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
function shell_exit() {
    errcode=$?

    END=$(date +%s)
    DIFF=$(echo "$END - $START" | bc)
    log "Track time spent: $DIFF seconds"
    if [ $errcode -eq 0 ]; then
        log "Load file successfully."
    else
        log "ERROR: Load file failed"
    fi

    log "rm tmp dir:${tmp_dir}"
    rm -rf "$tmp_dir"

    exit $errcode
}
########################################################################
trap shell_exit SIGHUP SIGINT SIGTERM 0

source_string "$env_parameters"

# Input Parameters check
check_list_fields "IP:TCP_PORT" "$from_server"
check_list_fields "IP:TCP_PORT" "$to_server_list"

log "Deploy to ${ssh_server_ip}:${ssh_port}"
log "From server: ${from_server}"

from_server_split=(${from_server//:/ })
from_ssh_server_ip=${from_server_split[0]}
from_ssh_port=${from_server_split[1]}

START=$(date +%s)

log "The parameter :package_location=${package_location}, package_new_location=${package_new_location}"

ssh_key_file="$HOME/.ssh/id_rsa"

common_ssh_options="-i $ssh_key_file -o StrictHostKeyChecking=no "

if [ -z "${package_location}" ];then
    log "The parameter package_location is invalid."
    exit 1
fi
if [ -z "${package_new_location}" ];then
    log "The parameter package_new_location is invalid."
    exit 1
fi

tmp_dir="/tmp/load_offline_package"
log "make tmp dir:${tmp_dir}"
[ -d $tmp_dir ] || mkdir -p $tmp_dir

package_tar_file=$(basename "$package_location")

log "scp $package_location to tmp dir:${tmp_dir}"
ssh_command="scp $common_ssh_options -P $from_ssh_port root@$from_ssh_server_ip:$package_location $tmp_dir/$package_tar_file"
$ssh_command

# Copy the file from the docker demo server or repo lab
for server in ${to_server_list}
do
    log "scp to server:$server"
    server_split=(${server//:/ })
    ssh_server_ip=${server_split[0]}
    ssh_port=${server_split[1]}

    ssh_command="ssh $common_ssh_options -p $ssh_port root@$ssh_server_ip [ -d $package_new_location ] || mkdir -p $package_new_location"
    $ssh_command

    ssh_command="scp $common_ssh_options -P $ssh_port $tmp_dir/$package_tar_file root@$ssh_server_ip:${package_new_location}"
    $ssh_command

    ssh_command="ssh $common_ssh_options -p $ssh_port root@${ssh_server_ip} tar zxf ${package_new_location}/${package_tar_file} -C ${package_new_location}/"
    $ssh_command

    ssh_command="ssh $common_ssh_options -p $ssh_port root@${ssh_server_ip} rm -f ${package_new_location}/${package_tar_file}"
    $ssh_command

    ssh_command="ssh $common_ssh_options -p $ssh_port root@${ssh_server_ip} chmod -R 755 ${package_new_location}"
    $ssh_command

    log "scp to server:$server ok"
done

log "Load package successfully."
## File : load_offline_package.sh ends
