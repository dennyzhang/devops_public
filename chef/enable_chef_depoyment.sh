#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : enable_chef_depoyment.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
## --
## Created : <2016-04-20>
## Updated: Time-stamp: <2016-05-25 12:50:57>
##-------------------------------------------------------------------
################################################################
# How To Use
#        export git_update_url="https://raw.githubusercontent.com/TEST/test/master/git_update.sh"
#        export ssh_email="auto.devops@test.com"
#
#        export ssh_public_key="AAAAB3NzaC1yc2EAAAADAQABAAABAQClL5PmH01x8eRPQ7FsodNT172ZIXiE2CT3RhBZpPpMFCdUyFTGBRfgbX/UE86MfycPHkzNnKemFNJOqFVdzK7eTIayxX9FYPOk+ONi2sbKkwAE4No+R0d4/ehoVzflbYXRWyxLqDKkqbJPDxY39xS2V7h4bSQWwrMyeYoGBn82AW5vSoonQMIrxe+bm6zWWtL6SzsYM/KNM1T+2pfU7Rq/YQPs2tf07rauyeT3bylhUf/CUqVPt2Xpf4qgmpGqp9Hyoy7FIfBHmCgXLRpia2KhpYr0j08s8cxBx1PEJiQ6EaWO2WlzyJIqgU2t9piDHEIUd6yCPmpshLtlOvno6KN5"
#
#        export ssh_config_content="Host github.com
#          StrictHostKeyChecking no
#          User git
#          HostName github.com
#          IdentityFile /root/.ssh/git_id_rsa"
#
#        export git_deploy_key="-----BEGIN RSA PRIVATE KEY-----
#        MIIJKgIBAAKCAgEAq6Jv5VPd82Lu2WE3R4/lNeA5Txckf3FE3aKRVBhRWy1ds1V9
#        ... ...
#        GnR17IjnTN5QS4/i6WhUuCU7F4OnIwjQETRCQtDJVU+VT5CKiIsUR7/VeaBruCFB
#        ZEtPc5dStJrtTrWRf1BOMlY/by7vaXII1Bkd+jSpLNqzfOpJdNWCaK+08bSOkA==
#        -----END RSA PRIVATE KEY-----"
#
#        bash ./enable_chef_depoyment.sh
################################################################
function log() {
    local msg=$*
    date_timestamp=$(date +['%Y-%m-%d %H:%M:%S'])
    echo -ne "$date_timestamp $msg\n"

    if [ -n "$LOG_FILE" ]; then
        echo -ne "$date_timestamp $msg\n" >> "$LOG_FILE"
    fi
}

################################################################
function enable_chef_deployment() {
    mkdir -p /root/.ssh/
    log "enable chef deployment"
    install_packages "wget" "wget"
    install_packages "curl" "curl"
    install_packages "git" "git"
    download_facility "$git_update_url" "/root/git_update.sh"
    inject_git_deploy_key "/root/.ssh/git_id_rsa" "$git_deploy_key"

    if [ -n "$ssh_config_content" ]; then
        git_ssh_config "/root/.ssh/config" "$ssh_config_content"
    fi

    inject_ssh_authorized_keys "$ssh_email" "$ssh_public_key"
    install_chef "$chef_version"
}

function install_chef() {
    local chef_version=${1?}
    if ! which chef-client 1>/dev/null 2>&1; then
        (echo "version=$chef_version"; curl -L https://www.opscode.com/chef/install.sh) |  bash
    fi
}

function install_packages() {
    local package=${1?}
    local binary_name=${2?}
    if ! which "$binary_name" 1>/dev/null 2>&1; then
        apt-get install -y "$package"
    fi
}

function download_facility() {
    local url=${1?}
    local dst_file=${2:?}
    if [ ! -f "$dst_file" ]; then
        command="wget -O $dst_file $url"
        log "$command"
        eval "$command"
        chmod 755 "$dst_file"
    fi
}

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

function inject_ssh_authorized_keys() {
    local ssh_email=${1?}
    local ssh_public_key=${2?}

    local ssh_authorized_key_file="/root/.ssh/authorized_keys"

    log "inject ssh authorized keys to $ssh_authorized_key_file"
    if ! grep "$ssh_email" $ssh_authorized_key_file 1>/dev/null 2>&1; then
        echo "ssh-rsa $ssh_public_key $ssh_email" >> $ssh_authorized_key_file
    fi
}
####################################
export chef_version="12.4.1"
if [ -z "$git_update_url" ]; then
   export git_update_url="https://raw.githubusercontent.com/TOTVS/mdmpublic/master/git_update.sh"
fi

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

if [ -z "$ssh_public_key" ] && [ -f "$ssh_public_key_file" ]; then
    export ssh_public_key
    ssh_public_key=$(cat "$ssh_public_key_file")
fi

# Use this key to checkout mdm devops code
if [ -z "$git_deploy_key" ]; then
    export git_deploy_key="-----BEGIN RSA PRIVATE KEY-----
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
-----END RSA PRIVATE KEY-----"
fi

enable_chef_deployment
echo "Action Done"
## File : enable_chef_depoyment.sh ends
