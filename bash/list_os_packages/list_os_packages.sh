#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
## https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : list_os_packages.sh
## Author : Denny <contact@dennyzhang.com>
## Description :
## Sample:
## list_os_packages.sh basic
## list_os_packages.sh all
## list_os_packages.sh python
## --
## Created : <2016-06-04>
## Updated: Time-stamp: <2017-09-04 18:54:43>
################################################################################################
. /etc/profile
[ -n "$DOWNLOAD_TAG_NAME" ] || export DOWNLOAD_TAG_NAME="tag_v6"
export DOWNLOAD_PREFIX="https://raw.githubusercontent.com/DennyZhang/devops_public/${DOWNLOAD_TAG_NAME}"
if [ ! -f /var/lib/devops/refresh_common_library.sh ]; then
    [ -d /var/lib/devops/ ] || (sudo mkdir -p  /var/lib/devops/ && sudo chmod 777 /var/lib/devops)
    wget -O /var/lib/devops/refresh_common_library.sh "$DOWNLOAD_PREFIX/common_library/refresh_common_library.sh"
    chmod 777 /var/lib/devops/refresh_common_library.sh
fi
bash /var/lib/devops/refresh_common_library.sh "3536991806" "/var/lib/devops/devops_common_library.sh" \
     "${DOWNLOAD_PREFIX}/common_library/devops_common_library.sh"
. /var/lib/devops/devops_common_library.sh
################################################################################################
# TODO: better way to update this bash common library
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
            java_packages=$(list_java_packages "$CLASSPATH")
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
