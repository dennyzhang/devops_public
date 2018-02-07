#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
## https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : ssh_login_report.sh
## Author : DennyZhang.com <contact@dennyzhang.com>
## Description :
##        TODO: known issues
##              no message to /var/log/secure
##              no ending time for some ssh session
##              sometimes no client ip tracked in auth.log
## --
## Created : <2016-04-03>
## Updated: Time-stamp: <2017-09-04 18:54:37>
##-------------------------------------------------------------------
################################################################################################
## env variables:
##      ssh_server: 192.168.1.3:2704:root
##      env_parameters:
##           export HAS_INIT_ANALYSIS=false
##           export WORKING_DIR=/tmp/auth
##           export PARSE_MAXIMUM_ENTRIES="5000"
##           export GET_CITY_FROM_IP=false
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
function compare_two_timestamp() {
    # Sample:
    #   From: Apr 19 12:01:43 -- Apr 19 12:18:23
    #   To: 16m40s
    start_time=${1?}
    end_time=${2?}
    return_str=$(date -d @$(( $(date -d "$end_time" +%s) - $(date -d "$start_time" +%s) )) -u +'%Hh:%Mm:%Ss')
    return_str=${return_str#00h:}
    return_str=${return_str#00m:}
    return_str=${return_str#0}
    echo "$return_str"
}

function prepare_auth_log_files() {
    local working_dir=${1?}
    local server_ip=${2?}
    local server_port=${3?}
    local ssh_username=${4?}

    cat > /tmp/copy_auth_files.sh <<EOF
#!/bin/bash -e
working_dir="$working_dir"
auth_log_dir="\$working_dir/auth_log"
auth_log_file="\$auth_log_dir/raw_ssh_login.log"

rm -rf \$working_dir
mkdir -p \$auth_log_dir
cd /var/log
if [ -f auth.log ]; then
    echo "Copy /var/log/auth.log* to \$auth_log_dir"
    for f in \$(ls -rt auth.log*); do
        cp \$f \$auth_log_dir/
        if [[ "\${f}" == *.gz ]]; then
            gzip -d \$auth_log_dir/\$f
            f=\${f%.gz}
        fi
        cat \$auth_log_dir/\$f >> \$auth_log_file
    done
else
    for f in \$(ls -rt secure*); do
        cp \$f \$auth_log_dir/
        cat \$auth_log_dir/\$f >> \$auth_log_file
    done
fi
EOF
    echo "Upload /tmp/copy_auth_files.sh"
    scp -i "$ssh_key_file" -P "$server_port" -o StrictHostKeyChecking=no /tmp/copy_auth_files.sh \
        "$ssh_username@$server_ip:/tmp/copy_auth_files.sh"

    $SSH_CONNECT "bash -e /tmp/copy_auth_files.sh"
}

function generate_ssh_login_log() {
    local working_dir=${1?}

    local ssh_login_logfile="$working_dir/ssh_login.log"
    local ssh_raw_logfile="$working_dir/auth_log/raw_ssh_login.log"

    echo "Dump ssh logs to $ssh_login_logfile"
    grep_command="grep -C 5 -h 'sshd.*session opened' $ssh_raw_logfile"
    command="$grep_command | grep sshd | grep -v 'Address already in use' | grep -v 'cannot listen to port'"
    command="$command | tail -n $PARSE_MAXIMUM_ENTRIES > $ssh_login_logfile"
    $SSH_CONNECT "$command"
}

function generate_fingerprint() {
    local working_dir=${1?}

    local fingerprint_file="$working_dir/fingerprint"
    echo "generate fingerprint for public key files to $fingerprint_file"
    command="cat /root/.ssh/authorized_keys /home/*/.ssh/authorized_keys | grep '^ssh-rsa'"
    tmp_file="/tmp/ssh_login_report_$$"

    fingerprint_result=""
    output=$($SSH_CONNECT "$command")
    # escape `, in case it's in files of authorized_keys
    output=$(echo -e "$output" | sed 's/`//g')
    IFS=$'\n'
    for entry in $output; do
        unset IFS
        # TODO: what if, email can't be found
        email=$(echo "$entry" | awk -F' ' '{print $3}')
        echo "$entry" > "$tmp_file"
        fingerprint=$(ssh-keygen -lf "$tmp_file")
        fingerprint_result="${fingerprint_result}\n${email} ${fingerprint}"
    done

    command="echo -e \"$fingerprint_result\" > $fingerprint_file"
    $SSH_CONNECT "$command"
}

function ip_to_city() {
    local ip=${1?}
    city="unknown"
    # TODO
    echo "$ip"
    echo "$city"
}

function parse_ssh_session() {
    # Sample return: May 9 22:31:02, sshd[619] 172.221.147.244:52740 (XXX), key_email, 0 seconds
    local session_id=${1?}
    local start_entry=${2?}
    local end_entry=${3?}
    local login_entry=${4?}
    local fingerprint_list=${5?}

    start_time=$(echo "$start_entry" | awk -F' ' '{print $1" "$2" "$3}')
    end_time=$(echo "$end_entry" | awk -F' ' '{print $1" "$2" "$3}')

    # parse login entry
    if echo "$login_entry" | grep "Accepted publickey" 1>/dev/null 2>&1; then
        auth_method="publickey"
        # sample: May 9 22:31:02 denny-pc sshd[619]: Accepted publickey for root from 171.221.147.244 port 52740 ssh2: RSA 2f:66:6c:2a:09:67:c0:ce:37:3f:96:a8:e9:aa:b5:ea
        fingerprint=$(echo "$login_entry" | awk -F' RSA ' '{print $2}')
        if output=$(echo "$fingerprint_list" | grep "$fingerprint" | awk -F' ' '{print $1}'); then
            fingerprint=$output
        fi

        # TODO: remove code duplication by bash regrexp pattern match
        ssh_username=$(echo "$login_entry" | awk -F' Accepted publickey for ' '{print $2}')
        ssh_username=$(echo "$ssh_username" | awk -F' ' '{print $1}')

        client_ip=$(echo "$login_entry" | awk -F' from ' '{print $2}')
        client_ip=$(echo "$client_ip" | awk -F' ' '{print $1}')

        client_port=$(echo "$login_entry" | awk -F' port ' '{print $2}')
        client_port=$(echo "$client_port" | awk -F' ' '{print $1}')
    fi

    if echo "$login_entry" | grep "Accepted password" 1>/dev/null 2>&1; then
        auth_method="password"
        # sample: May 13 17:03:54 denny-pc sshd[29980]: Accepted password for denny from ::1 port 60608 ssh2
        ssh_username=$(echo "$login_entry" | awk -F' Accepted password for ' '{print $2}')
        ssh_username=$(echo "$ssh_username" | awk -F' ' '{print $1}')

        client_ip=$(echo "$login_entry" | awk -F' from ' '{print $2}')
        client_ip=$(echo "$client_ip" | awk -F' ' '{print $1}')

        client_port=$(echo "$login_entry" | awk -F' port ' '{print $2}')
        client_port=$(echo "$client_port" | awk -F' ' '{print $1}')
    fi

    output_prefix="sshd[$session_id] ${start_time}"
    if [ -n "$end_time" ]; then
        time_offset=$(compare_two_timestamp "$start_time" "$end_time")
        if [ "$time_offset" == "0s" ]; then
            output_prefix="$output_prefix -- 0s"
        else
            output_prefix="$output_prefix -- duration($time_offset)"
        fi
    else
        output_prefix="$output_prefix -- $end_time"
    fi

    output_prefix="$output_prefix client(${client_ip}:${client_port}) ${ssh_username}"
    if [ "$auth_method" = "publickey" ]; then
        output_prefix="${output_prefix} ${auth_method}(${fingerprint})"
    fi

    if [ "$auth_method" = "password" ]; then
        output_prefix="${output_prefix} ${auth_method}"
    fi

    echo "$output_prefix"
}

function ssh_login_events() {
    local ssh_raw_log=${1?}
    local fingerprint_list=${2?}

    local entry
    ssh_session_list=$(echo "$ssh_raw_log" | grep 'session opened' | awk -F' ' '{print $5}')
    for session in $ssh_session_list; do
        session_id=$(echo "$session" | awk -F'[' '{print $2}')
        session_id=$(echo "$session_id" | awk -F']' '{print $1}')

        # TODO: what if no matched entries
        start_entry=$(echo "$ssh_raw_log" | grep "sshd\[$session_id\].*session opened" | head -n1)
        end_entry=$(echo "$ssh_raw_log" | grep "sshd\[$session_id\].*session closed" | tail -n1)
        login_entry=$(echo "$ssh_raw_log" | grep "sshd\[$session_id\].*Accepted " | tail -n1)

        # echo "start_entry: $start_entry"
        # echo "end_entry: $end_entry"
        # echo "login_entry: $login_entry"

        parse_ssh_session "$session_id" "$start_entry" "$end_entry" "$login_entry" "$fingerprint_list"
    done
}

function shell_exit() {
    errcode=$?
    rm -rf "$tmp_file"
    exit $errcode
}
################################################################################################
trap shell_exit SIGHUP SIGINT SIGTERM 0

source_string "$env_parameters"

[ -n "$ssh_key_file" ] || ssh_key_file="$HOME/.ssh/id_rsa"
[ -n "$WORKING_DIR" ] || WORKING_DIR=/tmp/auth
[ -n "$HAS_INIT_ANALYSIS" ] || HAS_INIT_ANALYSIS=false
[ -n "$PARSE_MAXIMUM_ENTRIES" ] || PARSE_MAXIMUM_ENTRIES="5000"
[ -n "$GET_CITY_FROM_IP" ] || GET_CITY_FROM_IP=false

# Input Parameters check
check_list_fields "IP:TCP_PORT:STRING" "$ssh_server"
enforce_ssh_check "true" "$ssh_server" "$ssh_key_file"

server_split=(${ssh_server//:/ })
server_ip=${server_split[0]}
server_port=${server_split[1]}
ssh_username=${server_split[2]}

[ -n "$ssh_username" ] || ssh_username="root"

SSH_CONNECT="ssh -i $ssh_key_file -p $server_port -o StrictHostKeyChecking=no $ssh_username@$server_ip"

if [ "$HAS_INIT_ANALYSIS" = "false" ]; then
    prepare_auth_log_files $WORKING_DIR "$server_ip" "$server_port" "$ssh_username"
    generate_ssh_login_log $WORKING_DIR
    generate_fingerprint $WORKING_DIR
fi

ssh_raw_log=$($SSH_CONNECT "tail -n $PARSE_MAXIMUM_ENTRIES $WORKING_DIR/ssh_login.log")
fingerprint_list=$($SSH_CONNECT "cat $WORKING_DIR/fingerprint")

echo -e "===================== SSH Login Events On $ssh_server:"
ssh_login_events "$ssh_raw_log" "$fingerprint_list"
## File : ssh_login_report.sh ends
