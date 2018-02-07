#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : replicate_git_repos.sh
## Author : DennyZhang.com <contact@dennyzhang.com>
## Description :
## --
## Created : <2016-04-13>
## Updated: Time-stamp: <2017-09-04 18:54:39>
##-------------------------------------------------------------------

################################################################################################
## env variables:
##      repo_list:
##        git@github.com:TEST/test.git,dev,git@gitlabcn.dennyzhang.com:customer/mdmdevops-test.git,dev
##        git@git.test.com:TEST/mytest.git,dev,git@gitlabcn.dennyzhang.com:customer/mdmdevops-mytest.git,dev
##
##       env_parameters:
##             export CLEAN_START=false
##             export working_dir="$HOME/code/replicate_git_repo"
################################################################################################
. /etc/profile
[ -n "$DOWNLOAD_TAG_NAME" ] || export DOWNLOAD_TAG_NAME="tag_v6"
export DOWNLOAD_PREFIX="https://raw.githubusercontent.com/DennyZhang/devops_public/${DOWNLOAD_TAG_NAME}"
if [ ! -f /var/lib/devops/refresh_common_library.sh ]; then
    [ -d /var/lib/devops/ ] || (sudo mkdir -p /var/lib/devops/ && sudo chmod 777 /var/lib/devops)
    wget -O /var/lib/devops/refresh_common_library.sh "$DOWNLOAD_PREFIX/common_library/refresh_common_library.sh"
    chmod 777 /var/lib/devops/refresh_common_library.sh
fi
bash /var/lib/devops/refresh_common_library.sh "3536991806" "/var/lib/devops/devops_common_library.sh" \
     "${DOWNLOAD_PREFIX}/common_library/devops_common_library.sh"
. /var/lib/devops/devops_common_library.sh
################################################################################################
function shell_exit() {
    errcode=$?
    exit $errcode
}

function git_directory_commit() {
    local code_dir=${1?}
    local branch_name=${2?}

    cd "$code_dir"
    git_status=$(git status)
    if echo "$git_status" | grep "nothing to commit, working directory clean" 1>/dev/null 2>&1; then
        echo "No change"
    else
        echo "Commit changes detected in intermediate directory"
        git_commit_message="Auto Push: Sync Code"

        echo "=========== Jenkins Robot push changes: $git_commit_message"
        echo "git_status: $git_status"

        git config user.email "$git_email"
        git config user.name "$git_username"
        git add ./*

        git commit -am "$git_commit_message"
        git push origin "$branch_name"
    fi
}

function git_update_dst_repo() {
    local branch_name=${1?}
    local working_dir=${2?}
    local git_repo_url=${3?}

    local git_repo
    git_repo=$(parse_git_repo "$git_repo_url")

    local code_dir="$working_dir/$branch_name/$git_repo"
    echo "Git update code for $git_repo_url to $code_dir"
    if [ ! -d "$working_dir/$branch_name/$git_repo" ]; then
        mkdir -p "$working_dir/$branch_name"
        cd "$working_dir/$branch_name"
        git clone "$git_repo_url"
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

    if git branch | grep "^* $branch_name" 1>/dev/null; then
        git checkout "$branch_name"
    else
        git checkout -b "$branch_name"
    fi
}

function replicate_git_repo() {
    local git_repo_src_url=${1?}
    local git_branch_src=${2?}
    local git_repo_dst_url=${3?}
    local git_branch_dst=${4?}
    local working_dir=${5?}

    local intermediate_dir
    local git_repo_src_name
    local git_repo_dst_name

    [ -d "$working_dir" ] || mkdir -p "$working_dir"
    intermediate_dir="$working_dir/$git_branch_dst/intermediate"
    git_repo_src_name=$(parse_git_repo "$git_repo_src_url")
    git_repo_dst_name=$(parse_git_repo "$git_repo_dst_url")

    git_update_code "$git_branch_src" "$working_dir" "$git_repo_src_url"
    git_update_dst_repo "$git_branch_dst" "$working_dir" "$git_repo_dst_url"

    echo "Update intermediate directory: $intermediate_dir"
    rm -rf "$intermediate_dir" && mkdir -p "$intermediate_dir"
    cp -r "$working_dir/$git_branch_dst/$git_repo_dst_name/.git" "$intermediate_dir/"
    src_dir="$working_dir/$git_branch_src/$git_repo_src_name/"
    for d in "${src_dir}/"*; do
        cp -r "$d" "$intermediate_dir/"
    done

    git_directory_commit "$intermediate_dir" "$git_branch_dst"
}

trap shell_exit SIGHUP SIGINT SIGTERM 0
########################################################
source_string "$env_parameters"
[ -n "$working_dir" ] || working_dir="$HOME/code/replicate_git_repo"
[ -d "$working_dir" ] || mkdir -p "$working_dir"

if [ -n "$CLEAN_START" ] && $CLEAN_START; then
    echo "Since clean_start is true, delete working_dir first: $working_dir"
fi

git_email="jenkins.auto@dennyzhang.com"
git_username="Jenkins Auto"

repo_list=$(string_strip_comments "$repo_list")
for repo in $repo_list; do
    repo=${repo//,/ }
    item=($repo)
    git_repo_src=${item[0]}
    git_branch_src=${item[1]}
    git_repo_dst=${item[2]}
    git_branch_dst=${item[3]}
    echo "Replicate $git_repo_src:$git_branch_src to $git_repo_dst:$git_branch_dst"
    replicate_git_repo "$git_repo_src" "$git_branch_src" "$git_repo_dst" "$git_branch_dst" "$working_dir"
done
## File : replicate_git_repos.sh ends
