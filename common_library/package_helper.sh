#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : package_helper.sh
## Author : Denny <contact@dennyzhang.com>
## Description :
## --
## Created : <2016-01-08>
## Updated: Time-stamp: <2017-09-04 18:54:41>
##-------------------------------------------------------------------
function install_package() {
    local package=${1?}
    local binary_name=${2:-""}
    [ -n "$binary_name" ] || binary_name="$package"

    # TODO: support more OS
    fail_unless_os "ubuntu"
    if ! which "$binary_name" 1>/dev/null 2>&1; then
        apt-get install -y "$package"
    fi
}

function install_package_list() {
    # install_package_list "wget,curl,git"
    local package_list=${1?}

    for package in ${package_list//,/ }; do
        install_package "$package"
    done
}

function ssh_apt_update() {
    set +e
    # Sample:
    #  ssh_apt_update "ssh -i $ssh_key_file -p $ssh_port -o StrictHostKeyChecking=no root@$ssh_server_ip"
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
    # TODO: unset -e without changing previous state
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

function install_chef() {
    local chef_version=${1:-"12.4.1"}
    if ! which chef-client 1>/dev/null 2>&1; then
        export version="$chef_version"
        wget -O /tmp/install.sh https://www.opscode.com/chef/install.sh
        bash -xe /tmp/install.sh
    fi
}

function install_ruby() {
    local ruby_version=${1:-"2.1.8"}
    echo "TODO: ruby_version: ${ruby_version}"

    # apt-get -yqq install python-software-properties && \
    # apt-add-repository ppa:brightbox/ruby-ng && \
    # apt-get -yqq update && \
    # apt-get -yqq install ruby2.1 ruby2.1-dev && \
    # rm -rf /usr/bin/ruby && \
    # ln -s /usr/bin/ruby2.1 /usr/bin/ruby && \
    # rm -rf /usr/local/bin/ruby /usr/local/bin/gem /usr/local/bin/bundle
}

function ubuntu_parse_package_list() {
    # parse output of "dpkg -l", to get package name and package version
    local package_list=${1?}
    package_list=$(echo "$package_list" | grep "^ii " | awk -F' ' '{print $2": "$3}')
    echo "$package_list"
}

function get_default_package_list() {
    # Related Link: https://github.com/DennyZhang/devops_public/tree/2016-06-16/os_preinstalled_packages
    local os_version=${1?}
    local package_file=${2:-""}
    local tag_name=${3:-"2016-06-16"}

    # TODO: don't hardcode download link
    package_prefix="https://github.com/DennyZhang/devops_public/raw/${tag_name}/os_preinstalled_packages"
    [ -n "$package_file" ] || package_file="/tmp/${os_version}.txt"

    case "$os_version" in
        ubuntu-14.04)
            package_link="${package_prefix}/${os_version}.txt"
            if [ ! -f "$package_file" ]; then
                command="wget -O $package_file $package_link"
                eval "$command"
            fi
            ;;
        *)
            echo "ERROR: Not supported OS: $os_version"
            exit 1
            ;;
    esac
}
######################################################################
## File : package_helper.sh ends
