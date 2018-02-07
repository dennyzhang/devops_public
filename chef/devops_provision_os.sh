#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : devops_provision_os.sh
## Author : Denny <contact@dennyzhang.com>
## Description :
#   curl -o /root/devops_provision_os.sh https://raw.githubusercontent.com/.../.../chef/devops_provision_os.sh
#   bash -e /root/devops_provision_os.sh
## --
## Created : <2016-04-20>
## Updated: Time-stamp: <2017-09-04 18:54:42>
################################################################################################
. /etc/profile
[ -n "$DOWNLOAD_TAG_NAME" ] || export DOWNLOAD_TAG_NAME="tag_v6"
export DOWNLOAD_PREFIX="https://raw.githubusercontent.com/DennyZhang/devops_public/${DOWNLOAD_TAG_NAME}"
if [ ! -f /var/lib/devops/refresh_common_library.sh ]; then
    [ -d /var/lib/devops/ ] || (sudo mkdir -p  /var/lib/devops/ && sudo chmod 777 /var/lib/devops)
    wget -O /var/lib/devops/refresh_common_library.sh "$DOWNLOAD_PREFIX/common_library/refresh_common_library.sh"
    chmod 777 /var/lib/devops/refresh_common_library.sh
fi
bash /var/lib/devops/refresh_common_library.sh "3536991806" "/var/lib/devops/devops_common_library.sh" \
     "${DOWNLOAD_PREFIX}/common_library/devops_common_library.sh"
. /var/lib/devops/devops_common_library.sh
################################################################################################
# TODO: better way to update this bash common library
ssh_port=${1:-"2702"}
chef_version="12.4.1"
ssh_email="auto.ci@devops.com"
ssh_public_key_file="/root/ssh_id_rsa.pub"
git_deploy_key_file="/root/git_deploy_key"

if [ -f "$ssh_public_key_file" ]; then
    export ssh_public_key
    ssh_public_key=$(cat "$ssh_public_key_file")
fi

if [ -f "$git_deploy_key_file" ]; then
    export git_deploy_key
    git_deploy_key=$(cat "$git_deploy_key_file")
fi
################################################################################
function disable_ipv6() {
    # TODO: persist the change
    sysctl -w net.ipv6.conf.all.disable_ipv6=1
    sysctl -w net.ipv6.conf.default.disable_ipv6=1
}

function change_vm_swappiness() {
    sysctl vm.swappiness=0
}

log "disable ipv6, due to known issue with Linode Provider"
disable_ipv6

# TODO: remove this, once the same logic has been integrated to chef
log "Change vm.swappiness=0, only use swap when all RAM is used"
change_vm_swappiness

log "enable chef deployment"
install_package_list "wget,curl,git,tmux,zip"
# TODO: error handling
install_chef $chef_version

download_facility "/root/git_update.sh" "${DOWNLOAD_PREFIX}/bash/git_update.sh"
download_facility "/root/manage_all_services.sh" "${DOWNLOAD_PREFIX}/bash/manage_all_services/manage_all_services.sh"
download_facility "/root/ufw_add_node_to_cluster.sh" "${DOWNLOAD_PREFIX}/bash/ufw/ufw_add_node_to_cluster.sh"
download_facility "/usr/sbin/examine_hosts_file.py" "${DOWNLOAD_PREFIX}/python/hosts_file/examine_hosts_file.py"
download_facility "/usr/sbin/update_hosts_file.py" "${DOWNLOAD_PREFIX}/python/hosts_file/update_hosts_file.py"
download_facility "/usr/sbin/node_usage.py" "${DOWNLOAD_PREFIX}/python/node_usage/node_usage.py"

# TODO:
# apt-get install -y python-dev python-pip

# pip install psutil==5.2.2

# inject ssh key for ssh with keyfile
if [ -n "$ssh_public_key" ]; then
    inject_ssh_authorized_keys "$ssh_email" "$ssh_public_key"
fi

# support git clone for DevOps code
if [ -n "$git_deploy_key" ]; then
    git_key_file="/root/.ssh/git_id_rsa"
    cat > "$git_key_file" <<EOF
$git_deploy_key
EOF
    chmod 400 "$git_key_file"
    cat > "/root/.ssh/config" <<EOF
Host github.com
  StrictHostKeyChecking no
  User git
  HostName github.com
  IdentityFile $git_key_file
EOF
fi

if ! which tmux 2>/dev/null 1>&2; then
    apt-get install -y tmux
fi

if [ "$ssh_port" != "22" ]; then
    echo "Change sshd port to $ssh_port"
    sed -i "s/Port 22/Port $ssh_port/g" /etc/ssh/sshd_config
    echo "Restart sshd to take effect"
    nohup service ssh restart &
fi

# TODO: enforce this in chef, instead of bash
echo "Create elasticsearch data path"
mkdir -p /usr/share/elasticsearch
chmod 777 /usr/share/elasticsearch

# TODO: make sure ruby and rubygems are properly installed
echo "Action Done. Note: sshd listen on $ssh_port."
## File : devops_provision_os.sh ends
