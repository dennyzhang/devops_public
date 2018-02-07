#!/bin/bash -ex
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : update_artifactserver.sh
## Author : DennyZhang.com <contact@dennyzhang.com>
## Description :
## --
## Created : <2015-08-05>
## Updated: Time-stamp: <2017-09-04 18:54:38>
##-------------------------------------------------------------------

################################################################################################
## env variables:
##       ssh_server_ip: 123.57.240.189
##       ssh_port:22
##       ssh_key_file:$HOME/.ssh/id_rsa
##       src_dir:/var/www/repo/dev
##       dst_dir:/var/www/repo/dev
##       tmp_dir:/tmp/artifact
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
source_string "$env_parameters"

# ssh_server_ip
[ -n "$tmp_dir" ] || tmp_dir="/root/artifact/"
[ -n "$src_dir" ] || src_dir="/var/www/repo/dev"
[ -n "$dst_dir" ] || dst_dir="/var/www/repo/dev"
[ -n "$ssh_key_file" ] || ssh_key_file="$HOME/.ssh/id_rsa"
[ -n "$ssh_port" ] || ssh_port="22"

ssh -i "$ssh_key_file" -p "$ssh_port" -o StrictHostKeyChecking=no "root@$ssh_server_ip" mkdir -p $tmp_dir

log "scp files from local machine to $ssh_server_ip"
scp -i "$ssh_key_file" -P "$ssh_port" -o StrictHostKeyChecking=no -r "$src_dir"/* "root@$ssh_server_ip:/${tmp_dir}/"

log "make symbol link"
ssh -i "$ssh_key_file" -p "$ssh_port" -o StrictHostKeyChecking=no "root@$ssh_server_ip" rm -rf $dst_dir
ssh -i "$ssh_key_file" -p "$ssh_port" -o StrictHostKeyChecking=no "root@$ssh_server_ip" ln -s "$tmp_dir" $dst_dir
## File : update_artifactserver.sh ends
