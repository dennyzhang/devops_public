#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## File : enable_latest_common_library.sh
## Author : Denny <denny@dennyzhang.com>
## Description : Use this file to update common library.
##               By default, this file keeps stable and untouched
## --
## Created : <2016-04-07>
## Updated: Time-stamp: <2016-04-07 09:44:42>
##-------------------------------------------------------------------
function refresh_common_library() {
    local library_file_checksum=${1?}
    local library_file=${2?}
    local library_url=${3?}
    if [ ! -f $library_file ]; then
        echo "download bash common library"
        wget -O $library_file $library_url
    else
        checksum=$(cksum $library_file | awk -F' ' '{print $1}')
        if [ "$library_file_checksum" != "$checksum" ]; then
            echo "refresh bash common library"
            wget -O $library_file $library_url
        fi
    fi
}

function enable_common_library() {
    local file_checksum=${1?}
    local library_file=${2?}
    local library_url=${3?}
    refresh_common_library $file_checksum $library_file $library_url
    . $library_file
}

file_checksum=${1?"checksum for common bash library"}
library_download_path=${2:-"/tmp/bash_common_library.sh"}
library_url=${3:-"https://raw.githubusercontent.com/DennyZhang/devops_public/master/bash/bash_common_library.sh"}
enable_common_library $file_checksum $library_download_path $library_url
## File : enable_latest_common_library.sh ends
