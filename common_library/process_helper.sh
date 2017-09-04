#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : process_helper.sh
## Author : Denny <contact@dennyzhang.com>
## Description :
## --
## Created : <2016-01-08>
## Updated: Time-stamp: <2017-09-04 18:54:41>
##-------------------------------------------------------------------
function remote_stop_process() {
    # Stop remote process by ssh
    # Sample: remote_stop_process $SSH_CONNECT "justniffer"
    local ssh_connect=${1?}
    local process_grep_pattern=${2?}
    local stop_command=${3:-""}
    [ -n "$stop_command" ] || stop_command="killall $process_grep_pattern"
    if $ssh_connect "pgrep $process_grep_pattern" 1>/dev/null 2>&1; then
        echo "Found live process of $process_grep_pattern. Kill the process: $stop_command"
        $ssh_connect "$stop_command"
    fi
}

function remote_start_process() {
    # Start remote process by ssh. If it's already running, skip it.
    # Sample: remote_start_process $SSH_CONNECT "justniffer" "nohup /usr/bin/justniffer -i eth0 ..."
    local ssh_connect=${1?}
    local process_grep_pattern=${2?}
    local start_command=${3?}
    if $ssh_connect "pgrep $process_grep_pattern" 1>/dev/null 2>&1; then
        echo "Skip starting process, since live process of $process_grep_pattern was found."
    else
        echo "Start process: $start_command"
        $ssh_connect "$start_command"
    fi
}
######################################################################
## File : process_helper.sh ends
