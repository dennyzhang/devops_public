#!/bin/bash -x
##-------------------------------------------------------------------
## @copyright 2015 DennyZhang.com
## File : chinese_chef_kitchen_provision.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
## --
## Created : <2015-11-30>
## Updated: Time-stamp: <2016-04-18 09:51:37>
##-------------------------------------------------------------------
# pre-cache Chef Omnibus installation
wget -O /tmp/chef_kitchen_provision.sh https://raw.githubusercontent.com/DennyZhang/devops_public/master/chef/chef_kitchen_provision.sh
bash -e /tmp/chef_kitchen_provision.sh

wget -O /tmp/ubuntu1404_inject_163_apt_source.sh https://raw.githubusercontent.com/DennyZhang/devops_public/master/network/ubuntu1404_inject_163_apt_source.sh
bash -e /tmp/ubuntu1404_inject_163_apt_source.sh
## File : chinese_chef_kitchen_provision.sh ends
