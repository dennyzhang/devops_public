#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : devops_provision_os.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
#   curl -o /root/devops_provision_os.sh https://raw.githubusercontent.com/.../.../chef/devops_provision_os.sh
#   bash -e /root/devops_provision_os.sh
## --
## Created : <2016-04-20>
## Updated: Time-stamp: <2016-07-08 11:28:19>
################################################################################################
. /etc/profile
[ -n "$DOWNLOAD_TAG_NAME" ] || export DOWNLOAD_TAG_NAME="tag_v2"
export DOWNLOAD_PREFIX="https://raw.githubusercontent.com/DennyZhang/devops_public/${DOWNLOAD_TAG_NAME}"
if [ ! -f /var/lib/devops/refresh_common_library.sh ]; then
    [ -d /var/lib/devops/ ] || (sudo mkdir -p  /var/lib/devops/ && sudo chmod 777 /var/lib/devops)
    wget -O /var/lib/devops/refresh_common_library.sh "$DOWNLOAD_PREFIX/common_library/refresh_common_library.sh"
fi
bash /var/lib/devops/refresh_common_library.sh "1523631277" "/var/lib/devops/devops_common_library.sh" \
     "${DOWNLOAD_PREFIX}/common_library/devops_common_library.sh"
. /var/lib/devops/devops_common_library.sh
################################################################################################
# TODO: better way to update this bash common library
chef_version="12.4.1"
ssh_email="auto.devops@totvs.com"
ssh_public_key_file="/root/ssh_id_rsa.pub"
git_deploy_key_file="/root/git_deploy_key"

if [ -z "$ssh_public_key" ] && [ -f "$ssh_public_key_file" ]; then
    export ssh_public_key
    ssh_public_key=$(cat "$ssh_public_key_file")
fi

if [ -z "$git_deploy_key" ] && [ -f "$git_deploy_key_file" ]; then
    export git_deploy_key
    git_deploy_key=$(cat "$git_deploy_key_file")
fi
################################################################################
log "enable chef deployment"
install_package_list "wget,curl,git"
install_chef $chef_version

download_facility "/root/git_update.sh" "${DOWNLOAD_PREFIX}/bash/git_update.sh"
download_facility "/root/manage_all_services.sh" "${DOWNLOAD_PREFIX}/bash/manage_all_services/manage_all_services.sh"

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

echo "Action Done"
## File : devops_provision_os.sh ends
