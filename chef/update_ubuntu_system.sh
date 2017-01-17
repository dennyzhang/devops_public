#!/bin/bash -e
##-------------------------------------------------------------------
## File : update_ubuntu_system.sh
## Author : Denny <denny.zhang@totvs.com>
## --
## Created : <2016-12-13>
## Updated: Time-stamp: <2016-12-13 09:40:32>
################################################################################################
. /etc/profile
# disable ipv6 to bypass Linode apt issue
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
apt-get -y update && apt-get -y upgrade
## File : update_ubuntu_system.sh ends
