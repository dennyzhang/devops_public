#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
## https://raw.githubusercontent.com/DennyZhang/devops_public/2016-06-23/LICENSE
##
## File : local_git_pull.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
##            Crontab to git pull, in order to automatically keep file in sync
##            This is especially useful, when your internet is slow or you
##            have multiple repo to keep in sync.
## --
## Created : <2016-04-20>
## Updated: Time-stamp: <2016-06-24 09:03:39>
##-------------------------------------------------------------------
function update_git() {
    dir=${1?}
    cd "$dir"
    current_branch=$(git status | grep "On branch" | awk -F' ' '{print $3}')
    log "cd $dir && git pull origin $current_branch"
    cd "$dir" && git pull origin "$current_branch"
}

# Sample: 
# update_git /Users/mac/backup/devops_code/iam/active-sprint
# update_git /Users/mac/backup/devops_code/iam/master
## File : local_git_pull.sh ends
