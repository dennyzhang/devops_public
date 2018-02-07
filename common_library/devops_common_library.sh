#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : devops_common_library.sh
## Author : Denny <contact@dennyzhang.com>
## Description :
## --
## Created : <2016-01-08>
## Updated: Time-stamp: <2017-09-04 18:54:42>
##-------------------------------------------------------------------
. /etc/profile
[ -n "$DOWNLOAD_TAG_NAME" ] || export DOWNLOAD_TAG_NAME="tag_v6"
export DOWNLOAD_PREFIX="https://raw.githubusercontent.com/DennyZhang/devops_public/${DOWNLOAD_TAG_NAME}"
# TODO: don't hardcode download link
if [ ! -f /var/lib/devops/refresh_common_library.sh ]; then
    [ -d /var/lib/devops/ ] || (sudo mkdir -p  /var/lib/devops/ && sudo chmod 777 /var/lib/devops)
    wget -O /var/lib/devops/refresh_common_library.sh \
         "$DOWNLOAD_PREFIX/common_library/refresh_common_library.sh"
    chmod 777 /var/lib/devops/refresh_common_library.sh
fi

library_list="
530252918 2332 docker_helper.sh
3456679356 7409 general_helper.sh
1029940671 3042 git_helper.sh
911553799 2979 language_helper.sh
2484023459 2371 network_helper.sh
3217412588 3914 package_helper.sh
4288579227 8855 paramater_helper.sh
4245606927 1639 process_helper.sh
1802790741 1904 refresh_common_library.sh
1527844233 2565 string_helper.sh
"

library_list=$(echo "$library_list" | grep "_helper.sh")
# source modules of common library
IFS=$'\n'
for library in $library_list; do
    unset IFS
    my_list=($library)
    cksum=${my_list[0]}
    fname=${my_list[2]}

    # TODO: don't hardcode download link
    bash /var/lib/devops/refresh_common_library.sh "$cksum" "/var/lib/devops/$fname" \
         "$DOWNLOAD_PREFIX/common_library/$fname"

    # source the library
    . "/var/lib/devops/$fname"
done
######################################################################
## File : devops_common_library.sh ends
