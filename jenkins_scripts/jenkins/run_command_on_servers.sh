#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : run_command_on_servers.sh
## Author : DennyZhang.com <denny@dennyzhang.com>
## Description :
## --
## Created : <2016-04-13>
## Updated: Time-stamp: <2016-07-08 11:27:12>
##-------------------------------------------------------------------
## env variables:
##       server_list: ip-1
##                    ip-2
##       command_list:
##        cat /etc/hosts
##        ls /opt/
##
##       env_parameters:
##          export EXIT_NODE_CONNECT_FAIL=false
##          export SSH_USERNAME="root"
##          export ssh_key_file="/var/lib/jenkins/.ssh/id_rsa"
################################################################################################
. /etc/profile
[ -n "$DOWNLOAD_TAG_NAME" ] || export DOWNLOAD_TAG_NAME="tag_v2"
export DOWNLOAD_PREFIX="https://raw.githubusercontent.com/DennyZhang/devops_public/${DOWNLOAD_TAG_NAME}"
if [ ! -f /var/lib/devops/refresh_common_library.sh ]; then
    [ -d /var/lib/devops/ ] || (sudo mkdir -p  /var/lib/devops/ && sudo chmod 777 /var/lib/devops)
    wget -O /var/lib/devops/refresh_common_library.sh "$DOWNLOAD_PREFIX/common_library/refresh_common_library.sh"
fi
bash /var/lib/devops/refresh_common_library.sh "4214886847" "/var/lib/devops/devops_common_library.sh" \
     "${DOWNLOAD_PREFIX}/common_library/devops_common_library.sh"
. /var/lib/devops/devops_common_library.sh
################################################################################################
function shell_exit() {
    errcode=$?
    rm -rf "$tmp_file" "$ansible_host_file"
    exit $errcode
}
################################################################################################
trap shell_exit SIGHUP SIGINT SIGTERM 0
source_string "$env_parameters"

[ -n "$ssh_key_file" ] || export ssh_key_file="/var/lib/jenkins/.ssh/id_rsa"
[ -n "$EXIT_NODE_CONNECT_FAIL" ] || export EXIT_NODE_CONNECT_FAIL=false
[ -n "$SSH_USERNAME" ] || export SSH_USERNAME="root"

server_list=$(string_strip_comments "$server_list")
server_list=$(string_strip_whitespace "$server_list")
command=$(string_strip_comments "$command")

install_package "ansible" "ansible"

# Dump bash command to scripts
current_filename=$(basename "${0}")
ansible_host_file="/tmp/${current_filename}_$$_hosts"
tmp_file="/tmp/${current_filename}_$$"
cat > "$tmp_file" <<EOF
$command_list
EOF

cat > "$ansible_host_file" <<EOF
$server_list
EOF

echo "==================== Parallel run command By Ansible:"
cat "$tmp_file"
echo "===================="

ansible all -i "$ansible_host_file" -m script -a "$tmp_file" -u "$SSH_USERNAME" "--private-key=$ssh_key_file"
## File : run_command_on_servers.sh ends
