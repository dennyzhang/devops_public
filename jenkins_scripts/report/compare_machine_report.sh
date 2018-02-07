#!/bin/bash -e
##-------------------------------------------------------------------
## File : compare_machine_report.sh
## Author : DennyZhang.com <contact@dennyzhang.com>
## Description :
## --
## Created : <2016-06-12>
## Updated: Time-stamp: <2017-09-04 18:54:37>
##-------------------------------------------------------------------

################################################################################################
## Purpose: Show installed packages and the specific version
##
## env variables:
##      ssh_server1: 192.168.1.3:2704:root
##      ssh_server2: 192.168.1.4:2704:root
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
[ -n "$OUTPUT_DIR" ] || OUTPUT_DIR="/tmp/version.d"
[ -n "$TRANSFER_DST_PATH" ] || TRANSFER_DST_PATH="$HOME/jobs/$JOB_NAME/workspace"
[ -n "$JENKINS_BASEURL" ] || JENKINS_BASEURL=$JENKINS_URL
[ -n "$ssh_key_file" ] || ssh_key_file="$HOME/.ssh/id_rsa"

# Input Parameters check
check_list_fields "IP:TCP_PORT:STRING" "$ssh_server1"
check_list_fields "IP:TCP_PORT:STRING" "$ssh_server2"
enforce_ssh_check "true" "$ssh_server1" "$ssh_key_file"
enforce_ssh_check "true" "$ssh_server2" "$ssh_key_file"

server_split1=(${ssh_server1//:/ })
server_ip1=${server_split1[0]}
server_port1=${server_split1[1]}
ssh_username1=${server_split1[2]}
[ -n "$ssh_username1" ] || ssh_username1="root"

SSH_CONNECT1="ssh -i $ssh_key_file -p $server_port1 -o StrictHostKeyChecking=no $ssh_username1@$server_ip1"

server_split2=(${ssh_server2//:/ })
server_ip2=${server_split2[0]}
server_port2=${server_split2[1]}
ssh_username2=${server_split2[2]}
[ -n "$ssh_username2" ] || ssh_username2="root"

SSH_CONNECT2="ssh -i $ssh_key_file -p $server_port2 -o StrictHostKeyChecking=no $ssh_username2@$server_ip2"
################################################################################################

# TODO: better way to update below script
bash_sh="/tmp/list_os_packages.sh"
$SSH_CONNECT1 wget -O "$bash_sh" "${DOWNLOAD_PREFIX}/bash/list_os_packages/list_os_packages.sh" \
              1>/dev/null 2>&1

$SSH_CONNECT2 wget -O "$bash_sh" "${DOWNLOAD_PREFIX}/bash/list_os_packages/list_os_packages.sh" \
              1>/dev/null 2>&1

command="bash -e $bash_sh $CHECK_SCENARIO $OUTPUT_DIR"

echo "=============== On $ssh_server1, run: $command"
$SSH_CONNECT1 "$command"

echo "=============== On $ssh_server2, run: $command"
$SSH_CONNECT2 "$command"

download_dir1="${server_ip1}-${server_port1}"
download_dir2="${server_ip2}-${server_port2}"
rm -rf "${TRANSFER_DST_PATH:?}"/*
cd "$TRANSFER_DST_PATH"
mkdir -p "$download_dir1" "$download_dir2"

scp_command1="scp -P $server_port1 -r -i $ssh_key_file -o StrictHostKeyChecking=no $ssh_username1@$server_ip1:${OUTPUT_DIR}/* $TRANSFER_DST_PATH/${download_dir1}/"
echo "=============== $scp_command1"
$scp_command1

scp_command2="scp -P $server_port2 -r -i $ssh_key_file -o StrictHostKeyChecking=no $ssh_username2@$server_ip2:${OUTPUT_DIR}/* $TRANSFER_DST_PATH/${download_dir2}/"
echo "=============== $scp_command2"
$scp_command2

cd "$TRANSFER_DST_PATH"
diff_command="diff -rq $download_dir1 $download_dir2"
echo "=============== $diff_command"
diff -rq "$download_dir1" "$download_dir2" || true

command="diff ${download_dir1}/os.txt ${download_dir2}/os.txt || true"
echo "=============== $command"
eval "$command"

if [ -n "$JENKINS_BASEURL" ]; then
    echo -e "=============== Download link:\n${JENKINS_BASEURL}/job/${JOB_NAME}/ws/"
fi
## File : compare_machine_report.sh ends
