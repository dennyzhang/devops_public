#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : string_manipulation.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
## --
## Created : <2016-01-08>
## Updated: Time-stamp: <2016-06-04 09:18:26>
##-------------------------------------------------------------------
function source_string() {
    # Global variables needed to enable the current script
    local env_parameters=${1?}
    IFS=$'\n'
    for env_variable in $env_parameters; do
        eval "$env_variable"
    done
    unset IFS
}

function remove_hardline() {
    # handle \n\r of Windows OS
    local str=$*
    echo "$str" | tr -d '\r'
}

function string_strip_whitespace() {
    # handle \n\r of Windows OS
    local str=$*
    str=$(echo "${str}" |sed -e 's/^[ \t]*//g')
    str=$(echo "${str}" |sed -e 's/[ \t]*$//g')
    echo "$str"
}

function string_strip_comments() {
    local my_str=${1?}
    my_str=$(echo "$my_str" | grep -v '^ *#')
    echo "$my_str"
}
######################################################################
## File : string_manipulation.sh ends
