#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : inject_ssh_key.sh
## Author : Denny <contact@dennyzhang.com>
## Description :
## --
## Created : <2015-05-13>
## Updated: Time-stamp: <2017-09-04 18:54:43>
##-------------------------------------------------------------------
user_home_list=${1?"To who the ssh key shall be injected. Users are separated by comma"}
ssh_email=${2?"email associated to this ssh key"}
ssh_key=${3?"ssh key"}

function inject_ssh_key() {
    local username=${1?}
    local home_dir=${2?}
    local ssh_email=${3?}
    local ssh_key=${4?}

    if [ ! -d "${home_dir}/.ssh" ] ; then
        echo "sudo mkdir -p $home_dir/.ssh"
        mkdir -p "${home_dir}/.ssh"
        chown "${username}:${username}" "${home_dir}/.ssh"
    fi

    if [ ! -f "${home_dir}/.ssh/authorized_keys" ]; then
        echo "touch $home_dir/.ssh/authorized_keys"
        touch "${home_dir}/.ssh/authorized_keys"
        chmod 644 "${home_dir}/.ssh/authorized_keys"
        chown "${username}:${username}" "${home_dir}/.ssh/authorized_keys"
    fi

    if ! grep "$ssh_key" "${home_dir}/.ssh/authorized_keys" 1>/dev/null; then
        command="echo \"ssh-rsa $ssh_key $ssh_email\" >> $home_dir/.ssh/authorized_keys"
        echo "$command"
        eval "$command"
    else
        echo "Skip. ssh key is already in $home_dir/.ssh/authorized_keys"
    fi
}

################################################################################
# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root." 1>&2
    exit 1
fi

username_list=${user_home_list//,/ }
for item in ${username_list[*]}; do
    user_home=(${item//:/ })
    username=${user_home[0]}
    home_dir=${user_home[1]}
    inject_ssh_key "$username" "$home_dir" "$ssh_email" "$ssh_key"
done
## File : inject_ssh_key.sh ends
