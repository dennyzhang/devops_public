#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : paramater_helper.sh
## Author : Denny <contact@dennyzhang.com>
## Description :
## --
## Created : <2016-01-08>
## Updated: Time-stamp: <2018-02-07 16:23:17>
##-------------------------------------------------------------------
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

function fail_unless_nubmer() {
    local var=${1?}
    local message=${2:-""}

    re='^[0-9]+$'
    if ! [[ $var =~ $re ]] ; then
        echo "Error: $var is not a valid number.${message}" 1>&2
        exit 1
    fi
}

function ensure_variable_isset() {
    # Sample: ensure_variable_isset "chef_client_rb must be set" "$chef_client_rb"
    local message=${1?"parameter name should be given"}
    local var=${2:-''}
    if [ -z "$var" ]; then
        echo "Error: $message" 1>&2
        exit 1
    fi
}

function is_ip() {
    local string=${1?}
    if [[ $string =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "true"
    else
        echo "false"
    fi
}

function is_tcp_port() {
    local string=${1?}
    if [[ $string =~ ^[0-9]+$ ]] ; then
        if [ "$string" -gt 65535 ] || [ "$string" -lt 0 ]; then
            echo "false"
        else
            echo "true"
        fi
    else
        echo "false"        
    fi
}

function check_string_schema() {
    # Sample:
    #     check_string_schema "172.17.0.5" "IP"
    #     check_string_schema "2701" "TCP_PORT"
    #     check_string_schema "root" "STRING"

    local string=${1?}
    local type=${2?}

    case "$type" in
	IP) ret=$(is_ip "$string");;
	TCP_PORT) ret=$(is_tcp_port "$string");;
	STRING) ret="true";;
	*) ret="true";;
    esac
    echo "$ret"
}

function check_list_fields() {
    # Sample:
    #    check_list_fields "STRING:IP:TCP_PORT:STRING" "root:172.17.0.5:22:/opt/devops/backup_wp_mysql.sh"
    #    check_list_fields "STRING:IP:TCP_PORT:STRING" "root:172.17.0.5:22:/opt/devops/backup_wp_mysql.sh
    #                                                   root:172.17.0.4:22:gitlab-rake gitlab:backup:create"
    #    check_list_fields "IP:TCP_PORT" "172.17.0.a:999999"
    local field_schema=${1?}
    local string=${2?}

    # get separator
    separator=","
    [[ "${field_schema}" == *\;* ]] && separator=";"
    [[ "${field_schema}" == *:* ]] && separator=":"

    IFS=$separator
    separator_list=($field_schema)
    
    error_msg=""
    IFS=$'\n'
    for line in ${string[*]}; do
        unset IFS

        IFS=$separator
        item=($line)
        unset IFS

        len=${#separator_list[@]}
        for((i=0; i<len; i++)); do {
            # echo "check_string_schema: ${item[i]}, ${separator_list[i]}"
            if [ "$(check_string_schema "${item[i]}" "${separator_list[i]}")" = "false" ]; then
                error_msg="${error_msg}\n${item[i]} is not valid ${separator_list[i]}"
            fi
        }; done
    done
    unset IFS

    if [ "$error_msg" != "" ] ; then
        echo -e "Error: Invalid parameters\n${error_msg}"
        exit 1
    fi
}

function ip_ssh_reachable() {
    # Check whether we can ssh to given server.
    #       Possible output: "ok", "Permission denied",
    #                        "ssh: connect to host XXX.XXX.XXX.XXX port XXX: Operation timed out"
    #                        "Connection timed out during banner exchange", etc
    #
    # Sample:
    #      ip_ssh_reachable "true" "172.17.0.2:22"
    #      ip_ssh_reachable "true" "172.17.0.2:22:root"
    #      ip_ssh_reachable "true" "172.17.0.2:22:root" "/var/lib/jenkins/.ssh/id_rsa"
    local exit_if_fail=${1?}
    local ssh_server=${2?}
    local ssh_keyfile=${3:-""}

    my_list=(${ssh_server//:/ })
    server_ip=${my_list[0]}
    server_port=${my_list[1]}
    ssh_username=${my_list[2]}
    [ -n "$ssh_port" ] || ssh_port="22"
    [ -n "$ssh_username" ] || ssh_username="root"

    echo "Check ssh connectivity for $server_ip:$server_port"
    ssh_timeout=8
    set +e
    if [ -n "$ssh_keyfile" ]; then
        ssh_connect="ssh -o BatchMode=yes -o ConnectTimeout=$ssh_timeout -o StrictHostKeyChecking=no -i $ssh_keyfile"
    else
        ssh_connect="ssh -o BatchMode=yes -o ConnectTimeout=$ssh_timeout -o StrictHostKeyChecking=no"
    fi
    status=$($ssh_connect -p "$server_port" "$ssh_username@$server_ip" echo ok 2>&1)
    # opt out message like: bash: warning: setlocale: LC_ALL: cannot change locale
    status=$(echo -e "$status" | grep -v "cannot change locale")
    # opt out message like: Warning: Permanently added '\''[172.17.0.3]:6022'\'' (ECDSA) to the list of known hosts.
    status=$(echo -e "$status" | grep -v "Warning: Permanently added")

    # TODO: restore previous state, instead of set -e
    set -e

    if [ "$status" != "ok" ]; then
        if [ "$exit_if_fail" = "true" ]; then
            echo -e "Error: Fail to ssh $ssh_server.\nError msg: $status"
            exit 1
        else
            echo -e "Warning: Fail to ssh $ssh_server.\nError msg: $status"
        fi
    fi
}

function ip_list_ping_reachable() {
    # Sample:
    #   ip_list_ping_reachable "true" "172.17.0.2
    #                                  172.17.0.3
    #                                  172.17.0.4"
    #   ip_list_ping_reachable "false" "$ip_list"
    local exit_if_fail=${1?}
    local ip_list=${2?}
    for ip in $ip_list; do
        # echo "ping ip: ${ip}"
        if ! ping -c3 "$ip" 2>/dev/null 1>/dev/null; then
            if [ "$exit_if_fail" = "true" ]; then
                echo "ERROR: Current machine can't ping $ip. Please check input parameters."
                exit 1
            else
                echo "Warning: Current machine can't ping $ip. Please check input parameters."
            fi
        fi
    done
}

function enforce_ssh_check() {
    # Sample:
    #   enforce_ssh_check "true" "$server_list" "/var/lib/jenkins/.ssh/id_rsa"
    local exit_if_fail=${1?}
    local server_list=${2:-""}
    local ssh_keyfile=${3:-""}
    if [ -n "$server_list" ]; then
        for server in $server_list; do
            ip_ssh_reachable "$exit_if_fail" "$server" "$ssh_keyfile"
        done
    fi
}

function enforce_ip_ping_check() {
    # Sample:
    #   enforce_ip_ping_check "true" "server_list" "$server_list"
    #   enforce_ip_ping_check "true" "chef_json" "$chef_json"
    local exit_if_fail=${1?}
    local parameter_name=${2?}
    local parameter_value=${3?}
    echo "ping ip address listed in $parameter_name parameter"
    ip_list=$(parse_ip_from_string "$parameter_value")
    if [ -n "$ip_list" ]; then
        ip_list_ping_reachable "$exit_if_fail" "$ip_list"
    fi
}

function parse_json() {
    # string manipulation for json
    local json=${1:-""}
    if [ -n "${json}" ]; then
        json=$(string_strip_comments "$json")
        json="$json"
        json=${json/#\{/}
        json=${json/%\}/}
    fi
    echo "$json"
}

function verify_ssh_key_file() {
    # verify ssh key file: it should exists and file mode should be fine
    local ssh_key_file=${1?}
    if [ ! -f "$ssh_key_file" ]; then
        echo "Error: ssh keyfile. $ssh_key_file doesn't exists"
        exit 1
    fi

    os_type=$(os_release)
    if [ "$os_type" = "osx" ]; then
        octal_mode=$(stat -f "%p" "$ssh_key_file")
    else
        octal_mode=$(stat -c "%a %n" "$ssh_key_file" | awk -F' ' '{print $1}')
    fi

    if [[ "${octal_mode}" != *00 ]]; then
        echo "Error: ssh keyfile. $ssh_key_file file mode is $octal_mode, instead of 400"
        exit 1
    fi
}

function verify_comon_jenkins_parameters() {
    if [ -n "$ssh_key_file" ]; then
        verify_ssh_key_file "$ssh_key_file"
    fi

    if [ -n "$server_list" ]; then
        check_list_fields "STRING:TCP_PORT" "$server_list"
    fi

    if [ -n "$server_list" ] && [ -n "$EXIT_NODE_CONNECT_FAIL" ]; then
        enforce_ip_ping_check "$EXIT_NODE_CONNECT_FAIL" "server_list" "$server_list"
    fi

    # TODO: temporarily disable ssh check to avoid network penalty
    # if [ -n "$ssh_key_file" ] && [ -n "$server_list" ] && [ -n "$EXIT_NODE_CONNECT_FAIL" ]; then
    #     enforce_ssh_check "$EXIT_NODE_CONNECT_FAIL" "$server_list" "$ssh_key_file"
    # fi
}
######################################################################
## File : paramater_helper.sh ends
