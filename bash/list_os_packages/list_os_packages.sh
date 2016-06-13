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
## Updated: Time-stamp: <2016-06-13 16:31:56>
##-------------------------------------------------------------------
. /etc/profile

function fail_unless_root() {
    # Make sure only root can run our script
    if [[ $EUID -ne 0 ]]; then
        echo "Error: This script must be run as root." 1>&2
        exit 1
    fi
}
################################################################################
function list_package_info() {
    command="dpkg -l"
    echo -e "\n=================== Run Command: $command"
    eval "$command"
}

function list_python_info() {
    command="pip list"
    echo -e "\n=================== Run Command: $command"
    eval "$command"
}

function list_ruby_info() {
    command="gem list"
    echo -e "\n=================== Run Command: $command"
    eval "$command"
}

function list_nodejs_info() {
    command="npm list"
    echo -e "\n=================== Run Command: $command"
    eval "$command"
}

function list_java_info() {
    command="echo TODO"
    echo -e "\n=================== Run Command: $command"
    eval "$command"
}

################################################################################
function list_basic_info() {
    echo "Dump OS Basic Info"
    uname -a
    # TODO: OS version, cpu, memory
}

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
output_dir=${2:-"/root/version.d"}

fail_unless_root
[ -d "$output_dir" ] || mkdir -p $output_dir

# defensive coding for not supported scenario
scenario_list="package python ruby nodejs java"
if [ "$check_scenario" = "all" ] || [ "$check_scenario" = "basic" ] \
       || [ *"$check_scenario"* = "$scenario_list" ]; then
    echo "yes"
else
    echo "ERROR: Not supported check scenario($check_scenario)."
    echo "Supported Scenarios: $scenario_list basic all."
    exit 1
fi

command="list_${check_scenario}_info"
echo "Run function: $command"

eval "$command"
## File: list_os_packages.sh ends
