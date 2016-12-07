#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : jenkins_code_pull.sh
## Author : DennyZhang.com <denny@dennyzhang.com>
## Description :
## --
## Created : <2015-07-03>
## Updated: Time-stamp: <2016-07-08 11:27:12>
##-------------------------------------------------------------------

################################################################################################
## env variables:
##      git_pull_list:
##               /var/lib/jenkins/code/bash_dir/,git@XXX:XXX/XXX.git,dev
##               /var/lib/jenkins/code/dockerfeaturemustpass/,git@XXX:XXX/XXX.git,dev
##               /var/lib/jenkins/code/dockerbasicmustpass/,git@XXX:XXX/XXX.git,dev
##               /var/lib/jenkins/code/dockerallinonemustpass/,git@XXX:XXX/XXX.git,dev
##               /var/lib/jenkins/code/codestylemustpass/,git@XXX:XXX/XXX.git,dev
################################################################################################
. /etc/profile
[ -n "$DOWNLOAD_TAG_NAME" ] || export DOWNLOAD_TAG_NAME="tag_v2"
export DOWNLOAD_PREFIX="https://raw.githubusercontent.com/DennyZhang/devops_public/${DOWNLOAD_TAG_NAME}"
if [ ! -f /var/lib/devops/refresh_common_library.sh ]; then
    [ -d /var/lib/devops/ ] || (sudo mkdir -p  /var/lib/devops/ && sudo chmod 777 /var/lib/devops)
    wget -O /var/lib/devops/refresh_common_library.sh "$DOWNLOAD_PREFIX/common_library/refresh_common_library.sh"
fi
bash /var/lib/devops/refresh_common_library.sh "1550237670" "/var/lib/devops/devops_common_library.sh" \
     "${DOWNLOAD_PREFIX}/common_library/devops_common_library.sh"
. /var/lib/devops/devops_common_library.sh
################################################################################################
function shell_exit() {
    errcode=$?
    exit $errcode
}

trap shell_exit SIGHUP SIGINT SIGTERM 0
########################################################################
git_pull_list=$(string_strip_comments "$git_pull_list")
for git_pull in $git_pull_list; do
    git_pull=${git_pull//,/ }
    item=($git_pull)
    working_dir=${item[0]}
    git_repo_url=${item[1]}
    branch_name=${item[2]}
    log "git pull in $working_dir"
    git_update_code "$branch_name" "$working_dir" "$git_repo_url"
done
## File : jenkins_code_pull.sh ends
