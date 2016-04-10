#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## File : enable_common_library.sh
## Author : Denny <denny@dennyzhang.com>
## Description : Use this file to update common library.
##               By default, this file keeps stable and untouched
## --
## Created : <2016-04-07>
## Updated: Time-stamp: <2016-04-10 10:49:19>
##-------------------------------------------------------------------
function refresh_common_library() {
    local library_file=${1?}
    local library_url=${2?}
    local library_file_checksum=${3?}
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
    local library_file=${1?}
    local library_url=${2?}
    local file_checksum=${3:-""}
    if [ "x${file_checksum}" = "x" ]; then
        wget -O $library_file $library_url
    else
        refresh_common_library $library_file $library_url $file_checksum
    fi
    . $library_file
}

# When checksum is not given, we will force re-download
file_checksum=${1:-"checksum for common bash library"}
library_download_path=${2:-"/var/lib/devops/devops_common_library.sh"}
library_url=${3:-"https://raw.githubusercontent.com/DennyZhang/devops_public/master/common_library/devops_common_library.sh"}

dir_name=$(dirname $library_download_path)
[ -d $dir_name ] || mkdir -p $dir_name

enable_common_library $library_download_path $library_url $file_checksum
## File : enable_common_library.sh ends
