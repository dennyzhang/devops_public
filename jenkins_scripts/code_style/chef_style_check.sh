#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : chef_style_check.sh
## Author : DennyZhang.com <contact@dennyzhang.com>
## Description :
##      Demo: http://jenkinscn.dennyzhang.com:18088/job/ChefCodeQualityCheck/
## --
## Created : <2016-04-25>
## Updated: Time-stamp: <2017-09-04 18:54:40>
##-------------------------------------------------------------------
################################################################################################
## env variables:
##      git_list:
##           git@github.com:DennyZhang/devops_public.git,dev
##           git@gitlabcn.dennyzhang.com:devops/devops_scripts.git,dev
##      env_parameters:
##           export working_dir="$HOME/code/codestyle"
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
function chefcheck_git_repo(){
    local branch_name=${1?}
    local working_dir=${2?}
    local git_repo_url=${3?}

    local git_repo
    git_repo=$(parse_git_repo "$git_repo_url")
    local code_dir="$working_dir/$branch_name/$git_repo"

    git_update_code "$branch_name" "$working_dir" "$git_repo_url"

    cd "$code_dir"
    if [ -d cookbooks ]; then
        cd cookbooks
        for cookbook in *; do
            if [ -d "$cookbook" ]; then
                command="foodcritic $cookbook"
                echo "======================== test $command"
                if ! eval "$command"; then
                    failed_git_repos="${failed_git_repos}\nfoodcritic: ${git_repo}:${branch_name}:${cookbook}"
                fi
            fi
        done

        for cookbook in *; do
            if [ -d "$cookbook" ]; then
                command="rubocop $cookbook"
                echo "======================== test $command"
                if ! eval "$command"; then
                    failed_git_repos="${failed_git_repos}\nrubocop: ${git_repo}:${branch_name}:${cookbook}"
                fi
            fi
        done
    else
        command="rubocop ."
        echo "======================== test $command"
        if ! eval "$command"; then
            failed_git_repos="${failed_git_repos}\nrubocop: ${git_repo}:${branch_name}"
        fi
    fi
}

function shell_exit() {
    errcode=$?
    if [ "$failed_git_repos" != "" ]; then
        echo -e "Failed Git Repos: $failed_git_repos"
        exit 1
    fi
    exit $errcode
}

################################################################################
trap shell_exit SIGHUP SIGINT SIGTERM 0

source_string "$env_parameters"
[ -n "$working_dir" ] || working_dir="$HOME/code/codestyle"

failed_git_repos=""

git_list=$(string_strip_comments "$git_list")
for git_repo_url in $git_list; do
    git_repo_url=${git_repo_url//,/ }
    item=($git_repo_url)
    git_repo_url=${item[0]}
    branch_name=${item[1]}
    chefcheck_git_repo "$branch_name" "$working_dir" "$git_repo_url"
done
## File : chef_style_check.sh ends
