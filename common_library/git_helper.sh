#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : git_helper.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
## --
## Created : <2016-01-08>
## Updated: Time-stamp: <2016-06-05 10:08:27>
##-------------------------------------------------------------------
function current_git_sha() {
    set -e
    local src_dir=${1?}
    cd "$src_dir"
    sha=$(git log -n 1 | head -n 1 | grep commit | head -n 1 | awk -F' ' '{print $2}')
    echo "$sha"
}

function git_log() {
    local code_dir=${1?}
    local tail_count=${2:-"10"}
    cd "$code_dir"
    command="git log -n $tail_count --pretty=format:\"%h - %an, %ar : %s\""
    echo -e "\n\nShow latest git commits: $command"
    eval "$command"
}

function git_update_code() {
    set -e
    local branch_name=${1?}
    local working_dir=${2?}
    local git_repo_url=${3?}

    local git_repo
    git_repo=$(echo "${git_repo_url%.git}" | awk -F '/' '{print $2}')

    local code_dir="$working_dir/$branch_name/$git_repo"
    echo "Git update code for $git_repo_url to $code_dir"
    # checkout code, if absent
    if [ ! -d "$working_dir/$branch_name/$git_repo" ]; then
        mkdir -p "$working_dir/$branch_name"
        cd "$working_dir/$branch_name"
        git clone --depth 1 "$git_repo_url" --branch "$branch_name" --single-branch
        cd "$code_dir"
        git config user.email "jenkins@devops.com"
        git config user.name "Jenkins Auto"
    else
        cd "$code_dir"
        git ls-remote --tags
        git config remote.origin.url "$git_repo_url"
        git config user.email "jenkins@devops.com"
        git config user.name "Jenkins Auto"
        # add retry for network turbulence
        git pull origin "$branch_name" || (sleep 2 && git pull origin "$branch_name")
    fi

    cd "$code_dir"
    git checkout "$branch_name"
    # git reset --hard
}
######################################################################
## File : git_helper.sh ends
