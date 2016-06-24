#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : devops_common_library.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
## --
## Created : <2016-01-08>
## Updated: Time-stamp: <2016-06-24 08:55:50>
##-------------------------------------------------------------------
. /etc/profile
[ -n "$DOWNLOAD_PREFIX" ] || export DOWNLOAD_PREFIX="https://raw.githubusercontent.com/DennyZhang/devops_public/master"
# TODO: don't hardcode download link
if [ ! -f /var/lib/devops/refresh_common_library.sh ]; then
    [ -d /var/lib/devops/ ] || (sudo mkdir -p  /var/lib/devops/ && sudo chmod 777 /var/lib/devops)
    wget -O /var/lib/devops/refresh_common_library.sh \
         "$DOWNLOAD_PREFIX/common_library/refresh_common_library.sh"
fi

library_list="
1306610065 1841 devops_common_library.sh
687148894 2330 docker_helper.sh
3909948268 7189 general_helper.sh
3725851651 2373 git_helper.sh
1919127727 2977 language_helper.sh
1959477722 2369 network_helper.sh
4102396658 3515 package_helper.sh
2212043494 8524 paramater_helper.sh
3217350404 1637 process_helper.sh
2238344795 1776 refresh_common_library.sh
3741144876 2060 string_helper.sh
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
