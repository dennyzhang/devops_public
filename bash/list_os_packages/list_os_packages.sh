#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
## https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : list_os_packages.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
## Sample:
## --
## Created : <2016-06-04>
## Updated: Time-stamp: <2016-06-12 18:05:05>
##-------------------------------------------------------------------
. /etc/profile

function list_basic_info() {
    echo "Dump OS Basic Info"
    uname -a
    # TODO: OS version, cpu, memory
}

function list_package_info() {
    command="dpkg -l"
    echo "OS installed packages: $command"
    eval "$command"
}

function list_python_info() {
    command="pip list"
    echo "List python packages: $command"
    eval "$command"
}

function list_ruby_info() {
    command="gem list"
    echo "List ruby packages: $command"
    eval "$command"
}

function list_nodejs_info() {
    command="npm list"
    echo "List npm packages: $command"
    eval "$command"
}

function list_java_info() {
    command="echo TODO"
    echo "List Java packages: $command"
    eval "$command"
}

################################################################################
function list_all_info() {
    list_basic_info
    list_package_info
    if which gem 2>/dev/null 1>&2; then
        list_ruby_info
    fi

    if which pip 2>/dev/null 1>&2; then
        list_python_info
    fi

    if which npm 2>/dev/null 1>&2; then
        list_nodejs_info
    fi

    if which java 2>/dev/null 1>&2; then
        list_java_info
    fi
}
################################################################################
# Sample:
#   list_os_packages.sh basic
#   list_os_packages.sh python
#   list_os_packages.sh all
check_scenario=${1:-"basic"}

command="list_${check_scenario}_info"
echo "Run $command"

# TODO: defensive coding for not supported scenario
eval "$command"
## File: list_os_packages.sh ends
