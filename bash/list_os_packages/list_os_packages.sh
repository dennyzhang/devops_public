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
## list_os_packages.sh basic
## list_os_packages.sh all
## list_os_packages.sh python
## --
## Created : <2016-06-04>
## Updated: Time-stamp: <2016-06-14 08:37:07>
##-------------------------------------------------------------------
. /etc/profile

function fail_unless_root() {
    # Make sure only root can run our script
    if [[ $EUID -ne 0 ]]; then
        echo "Error: This script must be run as root." 1>&2
        exit 1
    fi
}

function fail_unless_os() {
    # Sample: fail_unless_os "ubuntu/redhat/centos/osx"
    local supported_os=${1?}
    current_os=$(os_release)
    if [[ "$supported_os" != *"$current_os"* ]]; then
        echo "Error: supported OS are $supported_os, while current OS is $current_os" 1>&2
        exit 1
    fi
}

function python_basic_info() {
    # python basic info
    if which python 2>/dev/null 1>&2; then
        python_version=$(python --version 2>&1)
    else
        python_version="not found"
    fi
    if which pip 2>/dev/null 1>&2; then
        pip_version=$(pip --version)
        pip_package_count=$(pip list | wc -l)
    else
        pip_version="not found"
        pip_package_count="not found"
    fi

    echo "Python Version: $python_version
pip Version: $pip_version
pip Package Count: $pip_package_count"
}

function ruby_basic_info() {
    # ruby basic info
    if which ruby 2>/dev/null 1>&2; then
        ruby_version=$(ruby --version)
    else
        ruby_version="not found"
    fi

    if which gem 2>/dev/null 1>&2; then
        gem_version=$(gem --version)
        gem_package_count=$(gem list | wc -l)
    else
        gem_version="not found"
        gem_package_count="not found"
    fi

    echo "Ruby Version: $ruby_version
Gem Version: $gem_version
Gem Package Count: $gem_package_count"
}

function nodejs_basic_info() {
    # python basic info
    if which node 2>/dev/null 1>&2; then
        nodejs_version=$(node --version 2>&1)
    else
        nodejs_version="not found"
    fi
    if which npm 2>/dev/null 1>&2; then
        npm_version=$(npm --version)
        # TODO: get npm packages list
        npm_package_count=$(npm list | grep -c '\|')
    else
        npm_version="not found"
        npm_package_count="not found"
    fi

    echo "NodeJs Version: $nodejs_version
npm Version: $npm_version
npm Package Count: $npm_package_count"
}

function java_basic_info() {
    if which java 2>/dev/null 1>&2; then
        java_version=$(java -version 2>&1)
    else
        java_version="not found"
    fi
    . /etc/profile
    if [ -n "CLASSPATH" ]; then
        java_packages=$(list_java_packages "$CLASSPATH")
        java_package_count=$(echo "$java_packages" | wc -l)
    else
        java_package_count="CLASSPATH environment variable not set"
    fi

    echo "JAVA Version:
$java_version
JAVA Package Count: $java_package_count"
}

function list_java_packages() {
    local java_classpath=${1?}
    local tmp_file="/tmp/list_os_packages_$$.txt"
    > "$tmp_file"
    for path in ${java_classpath//:/ }; do
        ls -1 "${path}"/*.jar >> "$tmp_file"
    done
    cat "$tmp_file"
    rm -rf "$tmp_file"
}

function run_all_scenario() {
    local output_dir=${1?}
    local check_type=${2?}
    local scenario_list=${3?}
    for scenario in $scenario_list; do
        "list_${scenario}_info" "$output_dir" "$check_type"
    done
}

################################################################################
function list_os_info() {
    local output_dir=${1?}
    local check_type=${2?}
    local output_file="${output_dir}/os.txt"
    > "$output_file"

    echo -e "\nGenerate basic OS info to $output_file"
    command="cat /proc/version"
    echo "Run: $command"
    os_version=$(eval "$command")

    command="dpkg -l | grep -c '^ii'"
    echo "Run: $command"
    package_count=$(eval "$command")

    command="grep MemTotal /proc/meminfo | sed 's/ //g'"
    echo "Run: $command"
    total_memory=$(eval "$command")

    command="lsblk -P -o NAME,SIZE,MOUNTPOINT"
    echo "Run: $command"
    disk_info=$(eval "$command")

    command="lscpu"
    echo "Run: $command"
    cpu_info=$(eval "$command")
    cat > "$output_file" <<EOF
OS Version: $os_version
$total_memory
Disk Info:
$disk_info
Installed Package Count: $package_count
$(python_basic_info)
$(ruby_basic_info)
$(nodejs_basic_info)
$(java_basic_info)
CPU Info:
$cpu_info
EOF
}

function list_package_info() {
    local output_dir=${1?}
    local check_type=${2?}
    local output_file="${output_dir}/package.txt"
    > "$output_file"

    command="dpkg -l >> $output_file"
    echo -e "\nRun Command: $command"
    eval "$command"
}

function list_python_info() {
    local output_dir=${1?}
    local check_type=${2?}
    local output_file="${output_dir}/python.txt"

    if which pip 2>/dev/null 1>&2; then
        > "$output_file"
        command="pip list >> $output_file"
        echo -e "\nRun Command: $command"
        eval "$command"
    else
        echo "Warning list_python_info: nothing done, since no pip detected"
    fi
}

function list_ruby_info() {
    local output_dir=${1?}
    local check_type=${2?}
    local output_file="${output_dir}/ruby.txt"

    if which gem 2>/dev/null 1>&2; then
        > "$output_file"
        command="gem list >> $output_file"
        echo -e "\nRun Command: $command"
        eval "$command"
    else
        echo "Warning list_ruby_info: nothing done, since no gem detected"
    fi
}

function list_nodejs_info() {
    local output_dir=${1?}
    local check_type=${2?}
    local output_file="${output_dir}/nodejs.txt"

    if which npm 2>/dev/null 1>&2; then
        > "$output_file"
        command="npm list >> $output_file"
        echo -e "\nRun Command: $command"
        eval "$command"
    else
        echo "Warning list_nodejs_info: nothing done, since no npm detected"
    fi
}

function list_java_info() {
    local output_dir=${1?}
    local check_type=${2?}
    local output_file="${output_dir}/java.txt"

    if which java 2>/dev/null 1>&2; then
        > "$output_file"
        echo -e "\nlist *.jar found in CLASSPATH"
        if [ -n "$CLASSPATH" ]; then
            java_packages=$(list_java_packages)
            echo "$java_packages" >> "$output_file"
        fi
    else
        echo "Warning list_java_info: nothing done, since no java detected"
    fi
}

################################################################################
check_scenario=${1:-"basic"}
output_dir=${2:-"/root/version.d"}

fail_unless_root
fail_unless_os "ubuntu"

[ -d "$output_dir" ] || mkdir -p "$output_dir"

scenario_list="package python ruby nodejs java os"

case $check_scenario in
    all) run_all_scenario "$output_dir" "basic" "$scenario_list";;
    basic) run_all_scenario "$output_dir" "full" "$scenario_list";;
    *)
        if [ *"$check_scenario"* = "$scenario_list" ]; then
            command="list_${check_scenario}_info"
            echo "Run function: $command"
            "list_${check_scenario}_info" "$output_dir" "full"
        else
            echo "ERROR: Not supported check scenario($check_scenario)."
            echo "Supported Scenarios: $scenario_list basic all."
            exit 1
        fi
        ;;
esac
## File: list_os_packages.sh ends
