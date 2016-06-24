#!/bin/bash -x
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : chinese_chef_kitchen_provision.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
## --
## Created : <2015-11-30>
## Updated: Time-stamp: <2016-06-24 16:50:07>
##-------------------------------------------------------------------
# pre-cache Chef Omnibus installation
[ -n "$DOWNLOAD_PREFIX" ] || export DOWNLOAD_PREFIX="https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1"
wget -O /tmp/chef_kitchen_provision.sh "${DOWNLOAD_PREFIX}/chef/chef_kitchen_provision.sh"
bash -e /tmp/chef_kitchen_provision.sh

# TODO: don't hardcode download link
wget -O /tmp/ubuntu1404_inject_163_apt_source.sh "${DOWNLOAD_PREFIX}/bash/ubuntu1404_inject_163_apt_source.sh"
bash -e /tmp/ubuntu1404_inject_163_apt_source.sh
## File : chinese_chef_kitchen_provision.sh ends
