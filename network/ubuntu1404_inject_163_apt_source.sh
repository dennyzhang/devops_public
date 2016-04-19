#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT 
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : ubuntu1404_inject_163_apt_source.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
## --
## Created : <2016-04-18>
## Updated: Time-stamp: <2016-04-19 21:10:34>
##-------------------------------------------------------------------
cat > /etc/apt/sources.list.d/163.list <<EOF
deb-src http://mirrors.163.com/ubuntu/ trusty-updates main restricted
deb http://mirrors.163.com/ubuntu/ trusty universe
deb-src http://mirrors.163.com/ubuntu/ trusty universe
deb http://mirrors.163.com/ubuntu/ trusty-updates universe
deb-src http://mirrors.163.com/ubuntu/ trusty-updates universe
deb http://mirrors.163.com/ubuntu/ trusty multiverse
deb-src http://mirrors.163.com/ubuntu/ trusty multiverse
deb http://mirrors.163.com/ubuntu/ trusty-updates multiverse
deb-src http://mirrors.163.com/ubuntu/ trusty-updates multiverse
deb http://mirrors.163.com/ubuntu/ trusty-backports main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ trusty-backports main restricted universe multiverse
EOF

apt-get update
apt-get autoremove && apt-get clean && apt-get autoclean
## File : ubuntu1404_inject_163_apt_source.sh ends
