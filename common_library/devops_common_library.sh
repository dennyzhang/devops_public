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
## Updated: Time-stamp: <2016-06-04 16:46:16>
##-------------------------------------------------------------------
. /etc/profile
if [ ! -f /var/lib/devops/refresh_common_library.sh ]; then
    [ -d /var/lib/devops/ ] || (sudo mkdir -p  /var/lib/devops/ && sudo chmod 777 /var/lib/devops)
    wget -O /var/lib/devops/refresh_common_library.sh \
         https://raw.githubusercontent.com/DennyZhang/devops_public/master/common_library/refresh_common_library.sh
fi

library_list="
1736618634 2235 docker_helper.sh
1815676351 6692 general_helper.sh
3614625518 2119 git_helper.sh
2665088169 2703 network_helper.sh
2752552464 4895 paramater_helper.sh
2053133080 1929 string_helper.sh
"

library_list=$(echo "$library_list" | grep "_helper.sh")
# source modules of common library
IFS=$'\n'
for library in $library_list; do
    unset IFS
    my_list=($library)
    cksum=${my_list[0]}
    fname=${my_list[2]}

    bash /var/lib/devops/refresh_common_library.sh "$cksum" "/var/lib/devops/$fname" \
         "https://raw.githubusercontent.com/DennyZhang/devops_public/master/common_library/$fname"

    # source the library
    . "/var/lib/devops/$fname"
done
######################################################################
## File : devops_common_library.sh ends
