#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : devops_common_library.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
## --
## Created : <2016-01-08>
## Updated: Time-stamp: <2016-06-04 09:30:31>
##-------------------------------------------------------------------
. /etc/profile
if [ ! -f /var/lib/devops/refresh_common_library.sh ]; then
    [ -d /var/lib/devops/ ] || (sudo mkdir -p  /var/lib/devops/ && sudo chmod 777 /var/lib/devops)
    wget -O /var/lib/devops/refresh_common_library.sh \
         https://raw.githubusercontent.com/DennyZhang/devops_public/master/common_library/refresh_common_library.sh
fi

library_list="1736618634 2235 docker_helper.sh
3614625518 2119 git_helper.sh
2665088169 2703 network_helper.sh
81904668 3845 paramater_helper.sh
2140396035 1237 string_helper.sh"

# source modules of common library
IFS=$'\n'
for library in $(echo "$library_list" | grep "_helper.sh"); do
    unset IFS
    my_list=($library)
    cksum=${my_list[0]}
    fname=${my_list[2]}

    bash /var/lib/devops/refresh_common_library.sh "$cksum" "/var/lib/devops/$fname" \
         "https://raw.githubusercontent.com/DennyZhang/devops_public/master/common_library/$fname"

    # source the library
    . "/var/lib/devops/$fname"
done

######################################################################
# Section: general
function log() {
    local msg=$*
    date_timestamp=$(date +['%Y-%m-%d %H:%M:%S'])
    echo -ne "$date_timestamp $msg\n"

    if [ -n "$LOG_FILE" ]; then
        echo -ne "$date_timestamp $msg\n" >> "$LOG_FILE"
    fi
}

function generate_checksum() {
    local dst_dir=${1?}
    cd "$dst_dir"
    current_filename=$(basename "${0}")
    tmp_file="/tmp/${current_filename}_$$"
    > "$tmp_file"
    for f in *; do
        if [ "$f" != "checksum.txt" ]; then
            cksum "$f" >> "$tmp_file"
        fi
    done
    mv "$tmp_file" checksum.txt
}

function os_release() {
    set -e
    distributor_id=$(lsb_release -a 2>/dev/null | grep 'Distributor ID' | awk -F":\t" '{print $2}')
    if [ "$distributor_id" == "RedHatEnterpriseServer" ]; then
        echo "redhat"
    elif [ "$distributor_id" == "Ubuntu" ]; then
        echo "ubuntu"
    else
        if grep CentOS /etc/issue 1>/dev/null 2>/dev/null; then
            echo "centos"
        else
            if uname -a | grep '^Darwin' 1>/dev/null 2>/dev/null; then
                echo "osx"
            else
                echo "ERROR: Not supported OS"
            fi
        fi
    fi
}

function ssh_apt_update() {
    set +e
    # Sample: ssh_apt_update "ssh -i $ssh_key_file -p $ssh_port -o StrictHostKeyChecking=no root@$ssh_server_ip"
    local ssh_command=${1?}
    echo "Run apt-get -y update"
    apt_get_output=$($ssh_command apt-get -y update)
    if echo "$apt_get_output" | "Hash Sum mismatch" 1>/dev/null 2>&1; then
        echo "apt-get update fail with complain of 'Hash Sum mismatch'"
        echo "rm -rf /var/lib/apt/lists/*"
        $ssh_command "rm -rf /var/lib/apt/lists/*"
        echo "Re-run apt-get -y update"
        $ssh_command "apt-get -y update"
    fi
    set -e
}

function update_system() {
    local os_release_name
    os_release_name=$(os_release)
    if [ "$os_release_name" == "ubuntu" ]; then
        log "apt-get -y update"
        rm -rf /var/lib/apt/lists/*
        apt-get -y update
    fi

    if [ "$os_release_name" == "redhat" ] || [ "$os_release_name" == "centos" ]; then
        yum -y update
    fi
}
######################################################################
## File : devops_common_library.sh ends
