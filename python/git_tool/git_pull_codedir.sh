#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2017 DennyZhang.com
## Licensed under MIT 
##   https://www.dennyzhang.com/wp-content/mit_license.txt
##
## File : git_pull_codedir.sh
## Author : Denny <contact@dennyzhang.com>
## Description :
## Sample: bash git_pull_codedir.sh "/data/code_dir/repo1,/data/code_dir/repo2"
## --
## Created : <2017-06-04>
## Updated: Time-stamp: <2017-09-07 21:35:49>
##-------------------------------------------------------------------
# https://coderwall.com/p/rdi_wq/fix-could-not-open-a-connection-to-your-authentication-agent-when-using-ssh-add

# wget -O /usr/sbin/detect_existing_ssh_agent.sh \
#      https://github.com/DennyZhang/devops_public/raw/tag_v6/python/git_tool/detect_existing_ssh_agent.sh

code_dir_list=${1?}
ssh_agent_bash_file="/tmp/ssh_agent.sh"
bash -ex /usr/sbin/detect_existing_ssh_agent.sh "$ssh_agent_bash_file"
source $ssh_agent_bash_file

echo "export SSH_AUTH_SOCK=$SSH_AUTH_SOCK; export SSH_AGENT_PID=$SSH_AGENT_PID"
if [ ! -f /usr/sbin/git_pull_codedir.py ]; then
    echo "ERROR: /usr/sbin/git_pull_codedir.py is not found!"
    echo "Get it from: https://github.com/DennyZhang/devops_public/tree/master/python/git_tool"
    exit 1
fi

echo "python /usr/sbin/git_pull_codedir.py --code_dirs $code_dir_list"
python /usr/sbin/git_pull_codedir.py --code_dirs "$code_dir_list"
## File : git_pull_codedir.sh ends
