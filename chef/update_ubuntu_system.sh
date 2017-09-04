#!/bin/bash -e
##-------------------------------------------------------------------
## File : update_ubuntu_system.sh
## Author : Denny <contact@dennyzhang.com>
## --
## Created : <2016-12-13>
## Updated: Time-stamp: <2017-09-04 18:54:42>
################################################################################################
. /etc/profile
# disable ipv6 to bypass Linode apt issue
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
apt-get -y update && apt-get -y upgrade
## File : update_ubuntu_system.sh ends
