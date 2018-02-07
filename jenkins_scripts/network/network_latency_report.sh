#!/bin/bash -e
##-------------------------------------------------------------------
## File : network_latency_report.sh
## Author : DennyZhang.com <contact@dennyzhang.com>
## Description :
## --
## Created : <2016-06-14>
## Updated: Time-stamp: <2017-09-04 18:54:38>
##-------------------------------------------------------------------

################################################################################################
## env variables:
##      from_ssh_server: 192.168.1.2:2704:root
##      target_server_list:
##           192.168.1.3:2704:root
##           192.168.1.4:2704:root
##      env_parameters:
##          export CHECK_METHOD="ssh"
##          export TIMEOUT_THRESHOLD_MS="600"
##          export connect_key_file="/root/.ssh/test_id_rsa"
##          export ssh_key_file="$HOME/.ssh/id_rsa"
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
function upload_check_script() {
    local server_ip=${1?}
    local server_port=${2?}
    local ssh_username=${3?}
    local ssh_key_file=${4?}
    local tmp_file=${5?}

    echo "Upload $tmp_file to $server_ip:$server_port"
    cat > "$tmp_file" <<EOF
#!/bin/bash -e
function ping_latency() {
    server_ip=\${1?}
    command="ping -c5 \$server_ip 2>&1"
    output=\$(eval "\$command")
    if [ \$? -eq 0 ]; then
        latency=\$(echo "\$output" | grep 'round-trip' | awk -F'=' '{print \$2}' | awk -F'/' '{print \$2}')
        echo "\$latency"
    else
        latency=\$(echo "\$output" | tail -n1)
        echo "ERROR: \$latency"
    fi
}

function ssh_latency() {
    local ssh_ip=\${1?}
    local ssh_port=\${2?}
    local ssh_username=\${3?}
    local ssh_key_file=\${4?}

    if [ ! -f "\$ssh_key_file" ]; then
       echo "ERROR: Wrong ssh keyfile. \$ssh_key_file doesn't exist"
       exit 1
    fi

    ssh_connecttimeout=8
    start_timestamp=\$(date +%s%3N)
    command="ssh -o BatchMode=yes -o ConnectTimeout=\$ssh_connecttimeout -o StrictHostKeyChecking=no -i \$ssh_key_file -p \$ssh_port \$ssh_username@\$ssh_ip echo ok 2>&1"
    output=\$(eval "\$command")
    if [ \$? -eq 0 ]; then
        end_timestamp=\$(date +%s%3N)
        latency=\$(echo "(\$end_timestamp - \$start_timestamp)" | bc)
        echo "\$latency"
    else
        latency=\$(echo "\$output" | tail -n1)
        echo "ERROR: \$latency"
    fi
}

################################################################################
check_method=\${1?}
server_list=\${2?}
timeout_threshold_ms=\${3?}
ssh_key_file=\${4:-""}
output_file=\${5:-"/tmp/latency_report.log"}

has_error=false
eth0_ip=\$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print \$1}')
echo "\$check_method below servers from \$eth0_ip" > "\$output_file"
IFS=\$'\n'
for server in \${server_list}; do
    unset IFS
    server_split=(\${server//:/ })
    ssh_server_ip=\${server_split[0]}
    ssh_port=\${server_split[1]}
    ssh_username=\${server_split[2]}
    [ -n "\$ssh_username" ] || ssh_username="root"
    echo "\$check_method \$ssh_server_ip \$ssh_port"
    latency="ERROR unknown"
    case \$check_method in
        ping) latency=\$(ping_latency "\$ssh_server_ip");;
        ssh) latency=\$(ssh_latency "\$ssh_server_ip" "\$ssh_port" "\$ssh_username" "\$ssh_key_file");;
        *)
            echo "ERROR: not supported check_method(\$check_method)"
            exit 1
            ;;
    esac
    # Update result
    if echo "\$latency" | grep "ERROR: " 1>/dev/null 2>&1; then
        has_error=true
    else
        if [ "\$latency" -gt "\$timeout_threshold_ms" ]; then
            has_error=true
        fi
        latency="\${latency}ms"
    fi
    echo "\$ssh_server_ip:\$ssh_port \$latency" >> "\$output_file"
done
echo -e "\n========== Show Latency Report: \$(cat \$output_file)"

if \$has_error; then
   echo "ERROR: Some requests took more than \${timeout_threshold_ms}ms"
   exit 1
fi
EOF
    scp -i "$ssh_key_file" -P "$server_port" -o StrictHostKeyChecking=no "$tmp_file" \
        "$ssh_username@$server_ip:$tmp_file"
}

################################################################################################
source_string "$env_parameters"
[ -n "$ssh_key_file" ] || ssh_key_file="$HOME/.ssh/id_rsa"
[ -n "$CHECK_METHOD" ] || CHECK_METHOD="ssh"
[ -n "$TIMEOUT_THRESHOLD_MS" ] || TIMEOUT_THRESHOLD_MS="600"
tmp_file="/tmp/network_latency.sh"

from_ssh_server=$(string_strip_whitespace "$from_ssh_server")
from_ssh_server=$(string_strip_whitespace "$from_ssh_server")

target_server_list=$(string_strip_comments "$target_server_list")
target_server_list=$(string_strip_whitespace "$target_server_list")

# TODO: defensive coding for $connect_key_file

# Input Parameters check
verify_comon_jenkins_parameters
check_list_fields "IP:TCP_PORT:STRING" "$from_ssh_server"
check_list_fields "IP:TCP_PORT:STRING" "$target_server_list"
enforce_ssh_check "true" "$from_ssh_server" "$ssh_key_file"

server_split=(${from_ssh_server//:/ })
server_ip=${server_split[0]}
server_port=${server_split[1]}
ssh_username=${server_split[2]}

[ -n "$ssh_username" ] || ssh_username="root"

upload_check_script "$server_ip" "$server_port" "$ssh_username" "$ssh_key_file" "$tmp_file"
SSH_CONNECT="ssh -i $ssh_key_file -p $server_port -o StrictHostKeyChecking=no $ssh_username@$server_ip"

command="bash -e $tmp_file \"$CHECK_METHOD\" \"$target_server_list\" \"$TIMEOUT_THRESHOLD_MS\" \"$connect_key_file\""
echo "Run $CHECK_METHOD check from $server_ip:$server_port"

$SSH_CONNECT "$command"
## File : network_latency_report.sh ends
