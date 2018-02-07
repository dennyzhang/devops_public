#!/bin/bash -e
##-------------------------------------------------------------------
## File : package_list_report.sh
## Author : DennyZhang.com <contact@dennyzhang.com>
## Description :
## --
## Created : <2016-02-23>
## Updated: Time-stamp: <2017-09-04 18:54:37>
##-------------------------------------------------------------------

################################################################################################
## Purpose: Show installed packages and the specific version
##
## env variables:
##      ssh_server: 192.168.1.3:2704:root
##      env_parameters:
##          export CHECK_SCENARIO="all"
##          export OUTPUT_DIR="/root/version.d"
##          export JENKINS_BASEURL="http://123.57.240.189:58080"
##          export ssh_key_file="$HOME/.ssh/id_rsa"
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
[ -n "$CHECK_SCENARIO" ] || CHECK_SCENARIO="all"
[ -n "$OUTPUT_DIR" ] || OUTPUT_DIR="/root/version.d"
[ -n "$TRANSFER_DST_PATH" ] || TRANSFER_DST_PATH="$HOME/jobs/$JOB_NAME/workspace"
[ -n "$JENKINS_BASEURL" ] || JENKINS_BASEURL=$JENKINS_URL
[ -n "$ssh_key_file" ] || ssh_key_file="$HOME/.ssh/id_rsa"

# Input Parameters check
check_list_fields "IP:TCP_PORT:STRING" "$ssh_server"
enforce_ssh_check "true" "$ssh_server" "$ssh_key_file"

server_split=(${ssh_server//:/ })
server_ip=${server_split[0]}
server_port=${server_split[1]}
ssh_username=${server_split[2]}

[ -n "$ssh_username" ] || ssh_username="root"

SSH_CONNECT="ssh -i $ssh_key_file -p $server_port -o StrictHostKeyChecking=no $ssh_username@$server_ip"

# TODO: better way to update below script
bash_sh="/root/list_os_packages.sh"
$SSH_CONNECT wget -O "$bash_sh" "${DOWNLOAD_PREFIX}/bash/list_os_packages/list_os_packages.sh" \
             1>/dev/null 2>&1

command="bash -e $bash_sh $CHECK_SCENARIO $OUTPUT_DIR"
echo "=============== On $ssh_server, run: $command"
$SSH_CONNECT "$command"

download_dir="${server_ip}-${server_port}"
rm -rf "${TRANSFER_DST_PATH:?}"/*
cd "$TRANSFER_DST_PATH"
mkdir -p "$download_dir"

scp_command="scp -P $server_port -r -i $ssh_key_file -o StrictHostKeyChecking=no $ssh_username@$server_ip:${OUTPUT_DIR}/* $TRANSFER_DST_PATH/${download_dir}/"
echo "=============== $scp_command"
$scp_command

command="cat $TRANSFER_DST_PATH/${download_dir}/os.txt"
echo "=============== $command"
eval "$command"

# Print download link at the bottom
if [ -n "$JENKINS_BASEURL" ]; then
    echo -e "=============== Download link:\n${JENKINS_BASEURL}/job/${JOB_NAME}/ws/"
fi
## File : package_list_report.sh ends
