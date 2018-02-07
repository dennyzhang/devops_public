#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : effort_report.sh
## Author : DennyZhang.com <contact@dennyzhang.com>
## Description :
## --
## Created : <2015-10-13>
## Updated: Time-stamp: <2017-09-04 18:54:37>
##-------------------------------------------------------------------

################################################################################################
## env variables: working_dir, git_repo_url, branch_nae, start_weekday
##
## Example:
##      git_repo_url:"git@bitbucket.org:authright/devops_effort.git"
##      branch_name: dev
##      start_weekday:"2015-10-12"
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
function get_effort_summary() {
    #set -xe
    git_dir=${1?}
    start_pattern=${2?}
    end_pattern=${3?}
    result=""
    for f in ${git_dir}/*/effort.md; do
        if ! grep "$end_pattern" "$f" >/dev/null 2>&1 ; then
            end_pattern="$(date +'%Y')-"
            echo "Warning: Failed to find $end_pattern in $f. Choose another pattern: $end_pattern"
        fi
        content=$(awk "/$start_pattern/,/$end_pattern/" "$f" | grep -v "^$start_pattern" | grep -v '^=======' | grep -v "^$end_pattern")
        name=$(dirname "$f")
        name=${name##*/}
        result="${result}Member - ${name}:\n${content}\n---------------------------------\n\n"
    done
    echo -e "$result"
}
################################################################################################
[ -n "$working_dir" ] || working_dir="$HOME/code/$JOB_NAME"

if [ -z "$start_weekday" ]; then
    start_weekday=$(last_monday)
fi

start_pattern=$start_weekday
end_pattern=$(caculate_date "$start_pattern" "7*24*60*60") # 7days before

# checkout code
git_repo=$(parse_git_repo "$git_repo_url")
code_dir="$working_dir/$branch_name/$git_repo"
git_update_code "$branch_name" "$working_dir" "$git_repo_url" 1>/dev/null

# parse content
content=$(get_effort_summary "$code_dir" "$start_pattern" "$end_pattern")
echo "Show report"
title="DevOps周报"
echo -e "☆☆☆☆ ${title}: ${start_weekday} ☆☆☆☆\n\n$content"
echo "Report is generated"
## File : effort_report.sh ends
