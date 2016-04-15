#!/bin/bash -e
##-------------------------------------------------------------------
## File : git_update.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
## --
## Created : <2016-04-15>
## Updated: Time-stamp: <2016-04-15 17:55:03>
##-------------------------------------------------------------------
working_dir=${1?}
git_repo_url=${2?}
branch_name=${3?}

function git_update_code() {
    set -e
    local git_repo=${1?}
    local git_repo_url=${2?}
    local branch_name=${3?}
    local working_dir=${4?}

    echo "Git update code for '$git_repo_url' to $working_dir, branch_name: $branch_name"
    # checkout code, if absent
    if [ ! -d $working_dir/$git_repo ]; then
        mkdir -p $working_dir
        cd $working_dir
        git clone --depth 1 $git_repo_url --branch $branch_name --single-branch $git_repo
    else
        cd $working_dir/$git_repo
        git config remote.origin.url $git_repo_url
    fi

    cd $working_dir/$git_repo
    #git reset --hard
    git checkout $branch_name
    output=$(git pull origin $branch_name)
}

git_repo=$(echo ${git_repo_url%.git} | awk -F '/' '{print $2}')
git_update_code $git_repo $git_repo_url $branch_name $working_dir
## File : git_update.sh ends
