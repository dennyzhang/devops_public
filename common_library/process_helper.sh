#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : process_helper.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
## --
## Created : <2016-01-08>
## Updated: Time-stamp: <2016-06-22 20:51:54>
##-------------------------------------------------------------------
function remote_stop_process() {
    # Stop remote process by ssh
    # Sample: remote_stop_process $SSH_CONNECT "justniffer"
    local ssh_connect=${1?}
    local process_grep_pattern=${2?}
    local stop_command=${3:-""}
    [ -n "$stop_command" ] || stop_command="killall $grep_pattern"
    if $ssh_connect "pgrep $process_grep_pattern" 1>/dev/null 2>&1; then
        echo "Found live process of $process_grep_pattern."
        echo "Kill the process: $stop_command"
        $ssh_connect "$stop_command"
    fi
}

function remote_start_process() {
    # Start remote process by ssh. If it's already running, skip it.
    # Sample: remote_start_process $SSH_CONNECT "justniffer" "nohup /usr/bin/justniffer -i eth0 ..."
    local ssh_connect=${1?}
    local process_grep_pattern=${2?}
    local start_command=${3?}
    if $Ssh_connect "pgrep $process_grep_pattern" 1>/dev/null 2>&1; then
        echo "Found live process of $process_grep_pattern. Skip starting process"
    else
        echo "Start process: $start_command"
        $ssh_connect "$start_command"
    fi
}
######################################################################
## File : process_helper.sh ends
