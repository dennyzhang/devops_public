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
## Updated: Time-stamp: <2016-06-12 15:36:08>
##-------------------------------------------------------------------
. /etc/profile
# TODO: don't hardcode download link
if [ ! -f /var/lib/devops/refresh_common_library.sh ]; then
    [ -d /var/lib/devops/ ] || (sudo mkdir -p  /var/lib/devops/ && sudo chmod 777 /var/lib/devops)
    wget -O /var/lib/devops/refresh_common_library.sh \
         https://raw.githubusercontent.com/DennyZhang/devops_public/master/common_library/refresh_common_library.sh
fi

library_list="
687148894 2330 docker_helper.sh
2261784924 6805 general_helper.sh
1264158380 2094 git_helper.sh
1959477722 2369 network_helper.sh
2500447864 2410 package_helper.sh
1165283188 7295 paramater_helper.sh
2372162680 2063 string_helper.sh
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
         "https://raw.githubusercontent.com/DennyZhang/devops_public/master/common_library/$fname"

    # source the library
    . "/var/lib/devops/$fname"
done
######################################################################
## File : devops_common_library.sh ends
