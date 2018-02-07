#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : monitor_git_contentchanges.sh
## Author : DennyZhang.com <contact@dennyzhang.com>
## Description :
## --
## Created : <2016-12-31>
## Updated: Time-stamp: <2017-09-04 18:54:38>
##-------------------------------------------------------------------
################################################################################################
## env variables:
##      git_repo_url: git@bitbucket.org:XXX/XXX.git
##      filelist_to_monitor:
##          account/src/main/resources/XXX.properties
##          account/service/src/test/resources/XXX.js
##          audit/src/main/resources/XXX.properties
##          gateway/protection/src/main/resources/config/XXX.json
##          gateway/protection/src/main/resources/config/routes/XXX.json
##      monitor_pattern_list:
##          <version>
##      branch_name: dev
##      env_parameters:
##         export MARK_PREVIOUS_FIXED=false
##         export CLEAN_START=false
##         export SKIP_UPDATE_FLAGFILE=false
##         export working_dir=$HOME/code/monitorgitcontent
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
function git_changed_filelist() {
    set -e
    local src_dir=${1?}
    local old_sha=${2?}
    local new_sha=${3?}
    cd "$src_dir"
    git diff --name-only "$old_sha" "$new_sha"
}

function detect_changed_file() {
    set -e
    local src_dir=${1?}
    local old_sha=${2?}
    local new_sha=${3?}
    local files_to_monitor=${4?}
    local file_list
    file_list=$(git_changed_filelist "$src_dir" "$old_sha" "$new_sha")

    echo -e "\n\n========== git diff --name-only ${old_sha}..${new_sha}\n"
    echo -e "${file_list}\n"
    IFS=$'\n'
    for file in ${file_list[*]}; do
      if echo -e "$files_to_monitor" | grep "$file" 1>/dev/null 2>&1; then
         changed_file_list="$changed_file_list $file"
      fi
    done
}

flag_file="$HOME/$JOB_NAME.flag"

function shell_exit() {
    errcode=$?
    if [ -z "$SKIP_UPDATE_FLAGFILE" ] || [ "$SKIP_UPDATE_FLAGFILE" = "false" ]; then
        if [ $errcode -eq 0 ]; then
            echo "OK" > "$flag_file"
        else
            echo "ERROR" > "$flag_file"
        fi
    fi
    exit $errcode
}

function git_http_compare_link() {
    local git_repo_url=${1?}
    local revision1=${2?}
    local revision2=${3?}

    # Sample:
    #   git_repo_url: git@gitlabcn.dennyzhang.com:devops/mydevops.git
    #       str: gitlabcn.dennyzhang.com:customer
    #       group_name: devops
    #       git_repo: mydevops
    git_repo=$(parse_git_repo "$git_repo_url")
    str=${git_repo_url%.git}
    str=${str#git@}
    str=${str%/*}
    group_name=$(echo "${git_repo_url%/.*.git}" | awk -F '/' '{print $2}')
    git_domain_name=$(echo "$str" | awk -F':' '{print $1}')
    group_name=$(echo "$str" | awk -F':' '{print $2}')
    http_protocal="https"
    echo "${http_protocal}://${git_domain_name}/${group_name}/${git_repo}/compare/${revision1}...${revision2}"
}

########################################################################
trap shell_exit SIGHUP SIGINT SIGTERM 0
source_string "$env_parameters"
[ -n "$working_dir" ] || working_dir="$HOME/code/$JOB_NAME"

log "env variables. CLEAN_START: $CLEAN_START"

git_repo=$(parse_git_repo "$git_repo_url")
code_dir=$working_dir/$branch_name/$git_repo

filelist_to_monitor=$(string_strip_comments "$filelist_to_monitor")
monitor_pattern_list=$(string_strip_comments "$monitor_pattern_list")
if [ -n "$MARK_PREVIOUS_FIXED" ] && $MARK_PREVIOUS_FIXED; then
    rm -rf "$flag_file"
fi

# check previous failure
if [ -f "$flag_file" ] && [[ "$(cat "$flag_file")" = "ERROR" ]]; then
    echo "Previous check has failed"
    exit 1
fi

if [ -n "$CLEAN_START" ] && $CLEAN_START; then
    [ ! -d "$code_dir" ] || rm -rf "$code_dir"
fi

if [ ! -d "$working_dir" ]; then
    mkdir -p "$working_dir"
    chown -R jenkins:jenkins "$working_dir"
fi

if [ -d "$code_dir" ]; then
    old_sha=$(current_git_sha "$code_dir")
else
    old_sha=""
fi

# Update code
git_update_code "$branch_name" "$working_dir" "$git_repo_url"
code_dir="$working_dir/$branch_name/$git_repo"
changed_file_list=""

cd "$code_dir"
new_sha=$(current_git_sha "$code_dir")

subscribed_change_detected=false
if [ -z "$old_sha" ] || [ "$old_sha" = "$new_sha" ]; then
    echo -e "\n\n========== Latest git sha is $old_sha. No commits since last git pull\n\n"
else
    detect_changed_file "$code_dir" "$old_sha" "$new_sha" "$filelist_to_monitor"
    if [ -n "$changed_file_list" ]; then
        echo -e "\n\n========== git diff ${old_sha} ${new_sha}\n"
        echo -e "\n\n========== $(git_http_compare_link "$git_repo_url" "$old_sha" "$new_sha")\n"
        for file in $changed_file_list; do
            git config --global core.pager ""
            command="git diff $old_sha $new_sha $file | grep -iE '^- |^\+ '"
            output=$(eval "$command")
            for pattern in ${monitor_pattern_list[*]}; do
                if echo "$output" | grep "$pattern" 1>/dev/null 2>&1; then
                    echo -e "========== ERROR subscribed changes detected.\nChanged file($file)"
                    subscribed_change_detected=true
                fi
            done
        done
        if $subscribed_change_detected; then
            exit 1
        fi
    fi
fi
## File : monitor_git_contentchanges.sh ends
