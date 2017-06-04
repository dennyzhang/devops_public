#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2017 DennyZhang.com
## Licensed under MIT 
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : git_pull_codedir.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
## Sample: bash git_pull_codedir.sh "/data/code_dir/repo1,/data/code_dir/repo2"
## --
## Created : <2017-06-04>
## Updated: Time-stamp: <2017-06-04 16:26:33>
##-------------------------------------------------------------------
# https://coderwall.com/p/rdi_wq/fix-could-not-open-a-connection-to-your-authentication-agent-when-using-ssh-add

function detect_ssh_auth_sock() {
    # If no ssh agent is found, exit with error
    # TODO
    echo "/tmp/ssh-CQvj4eoYn5ha/agent.2340"
}

function get_agentid_from_authsock() {
    # Sample: /tmp/ssh-CQvj4eoYn5ha/agent.2340 -> 2340
    ssh_auth_sock=${1?}
    echo ${ssh_auth_sock##*.}
}

code_dir_list=${1?}
ssh_auth_sock=$(detect_ssh_auth_sock)
ssh_agent_id=$(get_agentid_from_authsock "ssh_auth_sock")
export SSH_AUTH_SOCK="$ssh_auth"
export SSH_AGENT_PID="$ssh_agent_id"

echo "export SSH_AUTH_SOCK=$ssh_auth; export SSH_AGENT_PID=$ssh_agent_id"
if [ ! -f /usr/sbin/git_pull_codedir.py ]; then
    echo "ERROR: /usr/sbin/git_pull_codedir.py is not found!"
    echo "Get it from: https://github.com/DennyZhang/devops_public/tree/master/python/git_tool"
    exit 1
fi

echo "python /usr/sbin/git_pull_codedir.py --code_dirs $code_dir_list"
python /usr/sbin/git_pull_codedir.py --code_dirs "$code_dir_list"
## File : git_pull_codedir.sh ends
