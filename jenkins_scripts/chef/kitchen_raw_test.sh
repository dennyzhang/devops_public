#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : kitchen_raw_test.sh
## Author : DennyZhang.com <contact@dennyzhang.com>
## Description :
## --
## Created : <2015-07-03>
## Updated: Time-stamp: <2017-09-04 18:54:40>
##-------------------------------------------------------------------

################################################################################################
## env variables:
##      KEEP_INSTANCE(boolean)
##      KEEP_FAILED_INSTANCE(boolean)
##      REMOVE_BERKSFILE_LOCK(boolean)
##      KITCHEN_VERIFY_SHOW_DEBUG(boolean)
##      KITCHEN_LOGLEVEL(debug, info, warn, error, fatal)
##      SKIP_KITCHEN_CONVERGE(boolean)
##      SKIP_KITCHEN_VERIFY(boolean)
################################################################################################
. /etc/profile
[ -n "$DOWNLOAD_TAG_NAME" ] || export DOWNLOAD_TAG_NAME="tag_v6"
export DOWNLOAD_PREFIX="https://raw.githubusercontent.com/DennyZhang/devops_public/${DOWNLOAD_TAG_NAME}"
if [ ! -f /var/lib/devops/refresh_common_library.sh ]; then
    [ -d /var/lib/devops/ ] || (mkdir -p /var/lib/devops/ && chmod 777 /var/lib/devops)
    wget -O /var/lib/devops/refresh_common_library.sh "$DOWNLOAD_PREFIX/common_library/refresh_common_library.sh"
    chmod 777 /var/lib/devops/refresh_common_library.sh
fi
bash /var/lib/devops/refresh_common_library.sh "3536991806" "/var/lib/devops/devops_common_library.sh" \
     "${DOWNLOAD_PREFIX}/common_library/devops_common_library.sh"
. /var/lib/devops/devops_common_library.sh
################################################################################################
function exec_kitchen_cmd() {
    export LANG="en_US.UTF-8"
    export LC_ALL="en_US.UTF-8"

    hooks_dir="$1/.kitchen.hooks"
    shift
    cmd=$1
    shift
    options=$*

    if [ -a "${hooks_dir}/pre-$cmd.sh" ];then
        log "start to exec kitchen hook: pre-$cmd.sh"
        bash -ex "${hooks_dir}/pre-$cmd.sh" && log "kitchen hook: pre-$cmd.sh exec done!"
    fi

    command="kitchen $cmd $options"
    log "exec kitchen command: $command"
    eval "$command"

    if [ -a "${hooks_dir}/post-$cmd.sh" ];then
        log "start to exec kitchen hook: post-$cmd.sh"
        bash -ex "${hooks_dir}/post-$cmd.sh" && log "kitchen hook: post-$cmd.sh exec done!"
    fi
}

function shell_exit() {
    errcode=$?
    log "shell_exit: KEEP_FAILED_INSTANCE: $KEEP_FAILED_INSTANCE, KEEP_INSTANCE: $KEEP_INSTANCE"
    if [ $errcode -eq 0 ]; then
        log "Kitchen test pass."
    else
        log "Kitchen test fail."
    fi

    # whether destroy instance
    if [ -n "$KEEP_INSTANCE" ] && $KEEP_INSTANCE; then
        log "keep instance as demanded."
    else
        if [ -n "$KEEP_FAILED_INSTANCE" ] && $KEEP_FAILED_INSTANCE && [ $errcode -ne 0 ];then
            log "keep instance"
        else
            log "destroy instance."
            exec_kitchen_cmd "${kitchen_dir}" destroy "$show_log"
        fi
    fi

    exit $errcode
}

trap shell_exit SIGHUP SIGINT SIGTERM 0

current_cookbook=$(pwd)
current_cookbook=${current_cookbook##*/}

if [ -z "$KITCHEN_VERIFY_SHOW_DEBUG" ]; then
    KITCHEN_VERIFY_SHOW_DEBUG=false
fi

if  [ -n "$KITCHEN_LOGLEVEL" ]; then
    show_log="-l $KITCHEN_LOGLEVEL"
fi

log "env variables. cookbok: $current_cookbook, KEEP_INSTANCE: $KEEP_INSTANCE, KEEP_FAILED_INSTANCE: $KEEP_FAILED_INSTANCE"
if [ -n "$REMOVE_BERKSFILE_LOCK" ] && $REMOVE_BERKSFILE_LOCK; then
    command="rm -rf Berksfile.lock"
    log "$command" && eval "$command"
fi

kitchen_dir=$(pwd)
exec_kitchen_cmd "${kitchen_dir}" list
if [ -z "$SKIP_KITCHEN_DESTROY" ] || ! $SKIP_KITCHEN_DESTROY; then
    exec_kitchen_cmd "${kitchen_dir}" destroy "$show_log"
else
    log "skip kitchen destroy"
fi
if [ -z "$SKIP_KITCHEN_CREATE" ] || ! $SKIP_KITCHEN_CREATE; then
    exec_kitchen_cmd "${kitchen_dir}" create "$show_log"
else
    log "skip kitchen create"
fi

if [ -z "$SKIP_KITCHEN_CONVERGE" ] || ! $SKIP_KITCHEN_CONVERGE; then
    exec_kitchen_cmd "${kitchen_dir}" converge  "$show_log"
else
    log "skip kitchen converge"
fi

if [ -z "$SKIP_KITCHEN_VERIFY" ] || ! $SKIP_KITCHEN_VERIFY; then
    if $KITCHEN_VERIFY_SHOW_DEBUG; then
        exec_kitchen_cmd "${kitchen_dir}" verify -l debug
    else
        exec_kitchen_cmd "${kitchen_dir}" verify "$show_log"
    fi
else
    log "skip kitchen verify"
fi
## File : kitchen_raw_test.sh ends
