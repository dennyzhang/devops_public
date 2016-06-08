#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : devops_provision_os.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
## --
## Created : <2016-04-20>
## Updated: Time-stamp: <2016-06-08 14:01:37>
##-------------------------------------------------------------------
. /etc/profile

if [ ! -f /var/lib/devops/refresh_common_library.sh ]; then
    [ -d /var/lib/devops/ ] || (sudo mkdir -p  /var/lib/devops/ && sudo chmod 777 /var/lib/devops)
    wget -O /var/lib/devops/refresh_common_library.sh \
         https://raw.githubusercontent.com/DennyZhang/devops_public/master/common_library/refresh_common_library.sh
fi

bash /var/lib/devops/refresh_common_library.sh
. /var/lib/devops/devops_common_library.sh
################################################################################
function inject_git_deploy_key() {
    local ssh_key=${1?}
    shift
    local ssh_key_content=$*

    log "inject git deploy key to $ssh_key"
    cat > "$ssh_key" <<EOF
$ssh_key_content
EOF
    chmod 400 "$ssh_key"
}

function git_ssh_config() {
    local ssh_config_file=${1?}
    shift
    local ssh_config_content="$*"

    log "configure $ssh_config_file"
    cat > "$ssh_config_file" <<EOF
$ssh_config_content
EOF
}

################################################################
if [ -z "$ssh_email" ]; then
    export ssh_email="auto.devops@totvs.com"
fi

if [ -z "$ssh_config_content" ]; then
    export ssh_config_content="Host github.com
  StrictHostKeyChecking no
  User git
  HostName github.com
  IdentityFile /root/.ssh/git_id_rsa"
fi

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

################################################################
log "enable chef deployment"
install_package_list "wget,curl,git"
install_chef "12.4.1"

download_facility "/root/git_update.sh" \
                  "https://github.com/DennyZhang/devops_public/raw/master/bash/git_update.sh"

download_facility "/root/manage_all_services.sh" \
                  "https://github.com/DennyZhang/devops_public/raw/master/bash/manage_all_services/manage_all_services.sh"

# inject ssh key for ssh with keyfile
if [ -n "$ssh_public_key" ]; then
    inject_ssh_authorized_keys "$ssh_email" "$ssh_public_key"
fi

# support git clone for DevOps code
if [ -n "$git_deploy_key" ]; then
    inject_git_deploy_key "/root/.ssh/git_id_rsa" "$git_deploy_key"
fi

if [ -n "$ssh_config_content" ]; then
    git_ssh_config "/root/.ssh/config" "$ssh_config_content"
fi

echo "Action Done"
## File : devops_provision_os.sh ends
