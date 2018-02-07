#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : sync_http_repo_server.sh
## Author : DennyZhang.com <contact@dennyzhang.com>
## Description :
## --
## Created : <2016-04-23>
## Updated: Time-stamp: <2017-09-04 18:54:39>
##-------------------------------------------------------------------

################################################################################################
## env variables:
##     repo_server: http://192.168.1.2:28000/dev
##     dst_path: /var/www/repo/download/
##     download_files:
##               doc-mgr/frontend/build/libs/XXX.war
##               configuration/rest/build/libs/XXX.war
##               gateway/war/build/libs/XXX.war
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
fail_unless_os "ubuntu/redhat/centos/osx"

# calculate checksum: cksum * > checksum.txt
checksum_link="$repo_server/checksum.txt"
checksum_file="/tmp/checksum.txt"
local_checksum_file="local_checksum.txt"

function get_local_checksum() {
    local working_dir=${1?}
    local filename=${2?}
    local local_checksum_file=${3?}
    cd "$working_dir"
    cksum=$(grep "$filename" "$local_checksum_file")
    echo "$cksum"
}

function update_local_checksum() {
    local working_dir=${1?}
    local filename=${2?}
    local local_checksum_file=${3?}
    cd "$working_dir"
    [ -f "$local_checksum_file" ] || touch "$local_checksum_file"
    cksum=$(cksum "$filename")
    current_filename=$(basename "${0}")
    tmp_file="/tmp/${current_filename}_$$"
    if grep "$filename" "$local_checksum_file" 1>/dev/null 2>&1; then
        grep -v "$filename" "$local_checksum_file" > "$tmp_file"
        mv "$tmp_file" "$local_checksum_file"
    fi
    echo "$cksum" >> "$local_checksum_file"
}

log "Download $checksum_link"
wget -O $checksum_file "$checksum_link" 1>/dev/null 2>&1

[ -d "$dst_path" ] || mkdir -p "$dst_path"

cd "$dst_path"
has_file_changed=false

download_files=$(remove_hardline "$download_files")
# Check whether to re-download packages, by comparing the checksum file
for f in $download_files; do
    f=$(basename "$f")
    if [ -f "$f" ]; then
        remote_checksum=$(grep "$f" "$checksum_file")
        errcode=$?
        if [ $errcode -ne 0 ]; then
            log "ERROR: Fail to find $f in $checksum_link"
            exit 1
        else
            # get local checksum
            local_checksum=$(get_local_checksum "$dst_path" "$f" "$local_checksum_file")
            if [ "$remote_checksum" != "$local_checksum" ]; then
                log "Re-download $f, since it is changed in server side"
                # Resume http Download
                wget -O "$f" "$repo_server/$f"
                has_file_changed=true
                update_local_checksum "$dst_path" "$f" "$local_checksum_file"
            fi
        fi
    else
        log "Download $f, since it's missing in local drive"
        wget -O "$f" "$repo_server/$f"
        has_file_changed=true
        update_local_checksum "$dst_path" "$f" "$local_checksum_file"
    fi
done

if ! $has_file_changed; then
    log "No files are changed in remote server, since previous download"
fi
## File : sync_http_repo_server.sh ends
