#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : language_helper.sh
## Author : Denny <contact@dennyzhang.com>
## Description :
## --
## Created : <2016-06-14>
## Updated: Time-stamp: <2017-09-04 18:54:41>
##-------------------------------------------------------------------
function python_basic_info() {
    # python basic info
    if which python 2>/dev/null 1>&2; then
        python_version=$(python --version 2>&1)
    else
        python_version="not found"
    fi
    if which pip 2>/dev/null 1>&2; then
        pip_version=$(pip --version)
        pip_package_count=$(pip list | grep -c "(")
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
        gem_package_count=$(gem list | grep -c "(")
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
        npm_package_count=$(npm list | grep -o '@')
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
    if [ -n "$CLASSPATH" ]; then
        java_packages=$(list_java_packages "$CLASSPATH")
        java_package_count=$(echo "$java_packages" | wc -l)
    else
        java_package_count="CLASSPATH environment variable not set"
    fi

    echo "JAVA Version: $java_version
JAVA Package Count: $java_package_count"
}

function list_java_packages() {
    local java_classpath=${1?}
    local tmp_file="/tmp/list_os_packages_$$.txt"
    > "$tmp_file"
    for path in ${java_classpath//:/ }; do
        if [ -d "$path" ] &&  ls -1 "${path}"/*.jar 1>/dev/null 2>&1; then
            ls -1 "${path}"/*.jar >> "$tmp_file"
        fi
    done
    sort "$tmp_file" | uniq
    rm -rf "$tmp_file"
}
######################################################################
## File : language_helper.sh ends
