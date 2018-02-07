#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : monitor_git_branch_list.sh
## Author : DennyZhang.com <contact@dennyzhang.com>
## Description :
## --
## Created : <2015-08-05>
## Updated: Time-stamp: <2017-09-04 18:54:38>
##-------------------------------------------------------------------
################################################################################################
## env variables:
##      git_repo_url: git@bitbucket.org:XXX/XXX.git
##      branch_name: dev
##      activesprint_branch_pattern: ^sprint-[0-9]+$
##      env_parameters:
##         export MARK_PREVIOUS_FIXED=false
##         export CLEAN_START=false
##         export SKIP_UPDATE_FLAGFILE=false
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
function git_ls_branch() {
    set -e
    local src_dir=${1?}
    cd "$src_dir"
    output=$(git ls-remote --heads origin)
    echo "$output" | awk -F'/' '{print $3}'
}

function detect_matched_branch() {
    # get all remote branches which match given pattern
    set -e
    local src_dir=${1?}
    local branch_pattern=${2?}
    branch_list=$(git_ls_branch "$src_dir")
    for branch in $branch_list; do
        if [[ $branch =~ $branch_pattern ]]; then
            echo "$branch"
        fi
    done
}

flag_file="$HOME/$JOB_NAME.flag"
previous_activesprint_file="$HOME/previous_activesprint_$JOB_NAME.flag"

function shell_exit() {
    errcode=$?
    if [ -z "$SKIP_UPDATE_FLAGFILE" ] || [ "$SKIP_UPDATE_FLAGFILE" = "false" ]; then
        if [ $errcode -eq 0 ]; then
            echo "OK" > "$flag_file"
        else
            echo "ERROR" > "$flag_file"
        fi
    else
        echo "$matched_branch_list" > "$previous_activesprint_file"
        rm -rf "$flag_file"
    fi
    exit $errcode
}
########################################################################
trap shell_exit SIGHUP SIGINT SIGTERM 0
source_string "$env_parameters"
[ -n "$working_dir" ] || working_dir="$HOME/code/$JOB_NAME"

git_repo=$(parse_git_repo "$git_repo_url")
code_dir="$working_dir/$branch_name/$git_repo"

if [ -n "$MARK_PREVIOUS_FIXED" ] && $MARK_PREVIOUS_FIXED; then
    rm -rf "$flag_file"
fi

if [ "$CLEAN_START" = "true" ]; then
    [ ! -d "$code_dir" ] || rm -rf "$code_dir"
    rm -rf "$flag_file"
    rm -rf "$previous_activesprint_file"
fi

# check previous failure
if [ -f "$flag_file" ] && [[ "$(cat "$flag_file")" = "ERROR" ]]; then
    echo "Previous check has failed"
    exit 1
fi

if [ ! -d "$working_dir" ]; then
    mkdir -p "$working_dir"
    chown -R jenkins:jenkins "$working_dir"
fi

touch "$previous_activesprint_file"
branch_whitelist=$(cat "$previous_activesprint_file")
echo -e "Previous ActiveSprint List: \n$branch_whitelist"

git_update_code "$branch_name" "$working_dir" "$git_repo_url"
matched_branch_list=$(detect_matched_branch "$code_dir" "$activesprint_branch_pattern")
echo -e "Potential Matched ActiveSprint List: \n$matched_branch_list"

if [ -n "$MARK_PREVIOUS_FIXED" ] && $MARK_PREVIOUS_FIXED; then
    echo "$matched_branch_list" > "$previous_activesprint_file"
    exit 0
fi

for branch in $matched_branch_list; do
    if [[ "${branch_whitelist}" == *"$branch"* ]]; then
        continue
    else
        echo "========== Matched branch: $branch"
        exit 1
    fi
done
## File : monitor_git_branch_list.sh ends
