#!/bin/bash -x
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : chinese_chef_kitchen_provision.sh
## Author : Denny <contact@dennyzhang.com>
## Description :
## --
## Created : <2015-11-30>
## Updated: Time-stamp: <2017-09-04 18:54:42>
##-------------------------------------------------------------------
# pre-cache Chef Omnibus installation
[ -n "$DOWNLOAD_TAG_NAME" ] || export DOWNLOAD_TAG_NAME="tag_v6"
export DOWNLOAD_PREFIX="https://raw.githubusercontent.com/DennyZhang/devops_public/${DOWNLOAD_TAG_NAME}"
wget -O /tmp/chef_kitchen_provision.sh "${DOWNLOAD_PREFIX}/chef/chef_kitchen_provision.sh"
bash -e /tmp/chef_kitchen_provision.sh

# TODO: don't hardcode download link
wget -O /tmp/ubuntu1404_inject_163_apt_source.sh "${DOWNLOAD_PREFIX}/bash/ubuntu1404_inject_163_apt_source.sh"
bash -e /tmp/ubuntu1404_inject_163_apt_source.sh
## File : chinese_chef_kitchen_provision.sh ends
