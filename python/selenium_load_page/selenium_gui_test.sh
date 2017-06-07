#!/bin/bash -e
##-------------------------------------------------------------------
## File : selenium_gui_test.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
## --
## Created : <2017-05-18>
## Updated: Time-stamp: <2017-06-07 18:22:58>
##-------------------------------------------------------------------
url_test=${1?}
bind_hosts_list=${2:-""}
test_py_script=${3:="/home/seluser/scripts/selenium_load_page.py"}
maximum_seconds=${4:-"30"}

working_dir="/root/selenium_test"
[ -d "$working_dir" ] || mkdir -p "$working_dir"
# Start docker container

# Destroy docker container
docker exec selenium python "$test_py_script" \
       --page_url "$url_test"  --max_load_seconds $maximum_seconds
################################################################################
## File : selenium_gui_test.sh ends
