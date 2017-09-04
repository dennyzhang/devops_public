#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : string_helper.sh
## Author : Denny <contact@dennyzhang.com>
## Description :
## --
## Created : <2016-01-08>
## Updated: Time-stamp: <2017-09-04 18:54:41>
##-------------------------------------------------------------------
function source_string() {
    # Global variables needed to enable the current script
    local env_parameters=${1?}
    tmp_file=/tmp/$$_$((RANDOM % 100))
    echo -e "$env_parameters" > "$tmp_file"
    . "$tmp_file"
    rm -rf "$tmp_file"
}

function remove_hardline() {
    # handle \n\r of Windows OS
    local str=$*
    echo "$str" | tr -d '\r'
}

function string_strip_whitespace() {
    # remove leading and tailing whitespace
    local str=$*
    str=$(echo "${str}" | sed -e 's/^[ \t]*//g')
    str=$(echo "${str}" | sed -e 's/[ \t]*$//g')
    # remove empty lines
    str=$(echo "${str}" | sed '/^$/d')
    echo "$str"
}

function string_strip_comments() {
    # remove "  # ..." from the string
    local my_str=${1?}
    my_str=$(echo "$my_str" | grep -v '^ *#')
    echo "$my_str"
}

function parse_ip_from_string() {
    # get ip addresses from string
    # Sample: 
        # parse_ip_from_string "{ 'common_basic':
        #        {
        #        # service hosts: deploy service to which host
        #        'couchbase_hosts':['172.17.0.2', '172.17.0.3'],
        #        'elasticsearch_hosts':['172.17.0.2', '172.17.0.3'],
        #        'mdm_hosts':['172.17.0.3', '172.17.0.4'],
        #        'haproxy_hosts':['172.17.0.2','172.17.0.3'],
        #        'nagios_server':'172.17.0.4',"
    # -->
    #      172.17.0.2
    #      172.17.0.3
    #      172.17.0.4
    local my_str=${1?}
    echo -e "$my_str" | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | sort | uniq
}

function caculate_date() {
    local start_date=${1?}
    local delta_seconds=${2?}
    echo "$start_date" | python -c "import sys, datetime, time; date = sys.stdin.readline().strip(); t = time.mktime(time.strptime(date,\"%Y-%m-%d\")); print (datetime.datetime.fromtimestamp(t) - datetime.timedelta(seconds=$delta_seconds)).strftime(\"%Y-%m-%d\")"
}

function last_monday() {
    python -c "import datetime; today = datetime.date.today(); print today - datetime.timedelta(days=today.weekday())"    
}

######################################################################
## File : string_helper.sh ends
