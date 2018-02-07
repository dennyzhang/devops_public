#!/bin/bash -e
################################################################################################
# * Author        : doungni
# * Email         : doungni@doungni.com
# * Last modified : 2016-01-06 17:05
# * Filename      : domain.sh
# * Description   :
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
function check_domain() {
    # Check command: jq, for deal with json format
    if ! command -v jq >/dev/null 2>&1; then
        sudo apt-get install jq -y
    fi
    errcode=$?
    # Versify command jq
    if [ $errcode -ne 0 ]; then
        log "Error: command(jq) not exist"
        exit 1
    fi

    # Get domain date_expires
    local count_v=0
    while [ $count_v -lt ${#apikey_list[@]} ]
    do
        api_url="http://api.whoapi.com/?apikey=${apikey_list[count_v]}&r=whois&domain=$1"

        ret=$(curl -m 10 --connect-timeout 10 -s -d "getcode=secret" "$api_url" | jq . | grep date_expires | awk -F "\"" '{print $4}'| awk '{print $1}')
        if [ -z "$ret" ]; then
            log "Current API cannot call or APIKEY exception or domain error"
            exit 1
        fi
        ex_ret=$(date +%s -d "$ret")
        cur_ret=$(date +%s)
        day_ret=$(((ex_ret-cur_ret)/86400))

        current_domain+=("\n$1, expired_date:$ret, $day_ret days from now")

        if [ $day_ret -lt 30 ]; then
            log "Warning: $1 will be date expired letter than 30"
            expired_domain+=("\n$1, expired_date:$ret, $day_ret days from now")
        fi

        # Domain list $2->$1
        shift
        count_v=$((count_v+1))
    done

    if [ ${#expired_domain[@]} -gt 0 ]; then
        log "Expired domain list: ${expired_domain[*]}"
        exit 1
    else
        log "Currently no expiration domain\nCurrent domain expires instructions:${current_domain[*]}"
    fi
}
################################################################################################
fail_unless_os "ubuntu"

# Jenkins parameter
if [ -n "$apikey_list" ]; then
    apikey_list=(${apikey_list// / })
else
    log "Apikey list is empty"
    exit 1
fi

if [ -n "$domain_list" ]; then
    domain_list=(${domain_list// / })
else
    log "Domain list is empty"
    exit 1
fi

check_domain "${domain_list[@]}"
## File : monitor_domain.sh ends
