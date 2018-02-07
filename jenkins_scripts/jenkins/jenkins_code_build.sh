#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : jenkins_code_build.sh
## Author : DennyZhang.com <contact@dennyzhang.com>
## Description :
## --
## Created : <2015-07-03>
## Updated: Time-stamp: <2017-09-04 18:54:39>
##-------------------------------------------------------------------
################################################################################################
## env variables:
##      git_repo_url: git@bitbucket.org:XXX/XXX.git
##      branch_name: dev
##      files_to_copy: gateway/war/build/libs/gateway-war-1.0-SNAPSHOT.war oauth2/rest-service/build/libs/oauth2-rest-1.0-SNAPSHOT.war
##      env_parameters:
##           export CLEAN_START=true
##           export FORCE_BUILD=false
##           export SKIP_COPY=false
##           export IS_PACK_FILE=false
##           export IS_GENERATE_SHA1SUM=false
##           export repo_dir=/var/www/repo
##           export working_dir=$HOME/code/build
##      build_command: make
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
function git_log() {
    local code_dir=${1?}
    local tail_count=${2:-"10"}
    cd "$code_dir"
    command="git log -n $tail_count --pretty=format:\"%h - %an, %ar : %s\""
    echo -e "\n\nShow latest git commits: $command"
    eval "$command"
    echo -e "\n"
}

function copy_to_reposerver() {
    # Upload Packages to local apache vhost
    local git_repo=${1?}
    shift
    local branch_name=${1?}
    shift
    local code_dir=${1?}
    shift
    local dst_dir=${1?}
    shift

    local files_list=$*
    cd "$code_dir"

    [ -d "$dst_dir" ] || mkdir -p "$dst_dir"
    for f in $files_list; do
        #if [[ "$f" == "$git_repo/"* ]]; then
        cp "$f" "$dst_dir/"
        #fi
    done
}

function pack_files(){
    # Pack war package.
    local file_dir=${1?}
    local git_repo=${2?}
    local base_name
    local package_name
    local sha1sum_name

    base_name=$(basename "$repo_dir")
    package_name="${base_name}_${git_repo}.tar.gz"
    sha1sum_name="${base_name}_${git_repo}.sha1"

    log "Packing the file ${package_name},please wait for a moment..."
    cd "$file_dir"
    rm -f "${package_name}"
    rm -f "${sha1sum_name}"
    tar zcf "${package_name}" ./*

    if [ -n "$IS_GENERATE_SHA1SUM" ] && $IS_GENERATE_SHA1SUM ;then
        log "Generate the sha1 check file ${sha1sum_name}"
        sha1sum "$package_name" > "$sha1sum_name"
        mv "$sha1sum_name" "$repo_dir"
    fi
    mv "$package_name" "$repo_dir"
}

flag_file="$HOME/$JOB_NAME.flag"

function shell_exit() {
    errcode=$?
    git_log "$code_dir"
    if [ $errcode -eq 0 ]; then
        echo "OK" > "$flag_file"
    else
        echo "ERROR" > "$flag_file"
    fi
    exit $errcode
}

########################################################################
[ -n "$working_dir" ] || working_dir="$HOME/code/$JOB_NAME"
# $GIT_BRANCH environment variable override $branch_name
[ -z "$GIT_BRANCH" ] || branch_name="$GIT_BRANCH"
# Build Repo
git_repo=$(parse_git_repo "$git_repo_url")
code_dir=$working_dir/$branch_name/$git_repo

trap shell_exit SIGHUP SIGINT SIGTERM 0

source_string "$env_parameters"

log "env variables. CLEAN_START: $CLEAN_START, SKIP_COPY: $SKIP_COPY, FORCE_BUILD: $FORCE_BUILD, build_command: $build_command"
if [ -n "$CLEAN_START" ] && $CLEAN_START; then
    [ ! -d "$code_dir" ] || sudo rm -rf "$code_dir"
fi

if [ ! -d "$working_dir" ]; then
    mkdir -p "$working_dir"
fi

if [ -d "$code_dir" ]; then
    old_sha=$(current_git_sha "$code_dir")
else
    old_sha=""
fi

# Update code
git_update_code "$branch_name" "$working_dir" "$git_repo_url"
code_dir="$working_dir/$branch_name/$git_repo"
cd "$code_dir"

new_sha=$(current_git_sha "$code_dir")
log "old_sha: $old_sha, new_sha: $new_sha"
if ! $FORCE_BUILD; then
    if [ "$old_sha" = "$new_sha" ]; then
        log "No new commit, since previous build"
        if [ -f "$flag_file" ] && [[ $(cat "$flag_file") = "ERROR" ]]; then
            log "Previous build has failed"
            exit 1
        else
            exit 0
        fi
    fi
fi

cd "$code_dir"

log "================= Build Environment ================="
env
log "\n\n\n"

log "================= Build code: cd $code_dir ================="
# sudo /usr/sbin/locale-gen --lang en_US.UTF-8
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

log "$build_command"
eval "$build_command"

log "================= Confirm files are generated ================="
for f in ${files_to_copy[*]};do
    if [ ! -f "$f" ]; then
        log "Error: $f is not created"
        exit 1
    fi
done

if [ -z "$repo_dir" ]; then
    repo_dir="/var/www/repo"
fi

dst_dir="${repo_dir}/${branch_name}"
if [ -n "$files_to_copy" ] && ! $SKIP_COPY; then
    log "================= Generate Packages ================="
    copy_to_reposerver "$git_repo" "$branch_name" "$code_dir" "$dst_dir" "$files_to_copy"

    log "================= Generate checksum ================="
    generate_dir_checksum "${dst_dir}"

    if [ -n "$IS_PACK_FILE" ] && $IS_PACK_FILE ;then
        log "================= Pack war file =================="
        pack_files "${dst_dir}" "$git_repo"
    fi
fi
## File : jenkins_code_build.sh ends
