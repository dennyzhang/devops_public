#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
## https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : local_git_pull.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
##            Crontab to git pull, in order to automatically keep file in sync
##            This is especially useful, when your internet is slow or you
##            have multiple repo to keep in sync.
## --
## Created : <2016-04-20>
## Updated: Time-stamp: <2016-06-24 15:52:56>
##-------------------------------------------------------------------
function update_git() {
    dir=${1?}
    cd "$dir"
    current_branch=$(git status | grep "On branch" | awk -F' ' '{print $3}')
    log "cd $dir && git pull origin $current_branch"
    cd "$dir" && git pull origin "$current_branch"
}

# Sample: 
# update_git /Users/mac/backup/devops_code/iam/dev
# update_git /Users/mac/backup/devops_code/iam/sprint-32
## File : local_git_pull.sh ends
