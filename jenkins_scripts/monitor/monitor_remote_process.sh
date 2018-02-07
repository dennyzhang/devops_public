#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT 
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : monitor_remote_process.sh
## Author : Denny <contact@dennyzhang.com>
## Description :
## --
## Created : <2016-05-02>
## Updated: Time-stamp: <2017-09-04 18:54:38>
##-------------------------------------------------------------------

################################################################################################
## env variables:
##      process_list:
##          $server_ip:$server_port:root:pid:123
##          $server_ip:$server_port:root:cmdpattern:xxxx
##      env_parameters:
##         export UPDATE_SERVER_SCRIPT=true
##         export HISTORY_DIR="/opt/monitor_process/"
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
function shell_exit() {
    errcode=$?
    exit $errcode
}

function generate_monitor_script() {
    cat > "$monitor_process_path" << EOF
#!/bin/bash -e
function run_command() {
    local log_file=\${1?}
    local command=\${2?}
    date_timestamp=\$(date +['%Y-%m-%d %H:%M:%S'])

    local msg=\$(eval "\$command")

    echo -ne "\$date_timestamp \$command\n\$msg\n"
    echo -ne "\$date_timestamp \$command\n\$msg\n" >> "\$log_file"
}

history_dir=\${1?}
pid=\${2?}

run_command "\$history_dir/os.log" "free -ml"
run_command "\$history_dir/process_mem.log" "pmap -x \$pid | tail -n1"
run_command "\$history_dir/process_stat.log" "cat /proc/\$pid/stat"

EOF
}

function monitor_remote_process() {
    local server_ip=${1?}
    local server_port=${2?}
    local ssh_username=${3?}
    local process_pattern=${4?}
    local process_id=${5?}

    ssh_connect="ssh -p $server_port -o StrictHostKeyChecking=no $ssh_username@$server_ip"
    # get process pid
    local pid
    case "$process_pattern" in
        pid)
            pid=$process_id
            ;;
        cmdpattern)
            ssh_command="ps -ef | grep \"$process_id\" | grep -v grep | awk -F' ' '{print \$2}'"
            pid=$($ssh_connect "$ssh_command")
            ;;
        *)
            echo "ERROR: not supported process_pattern($process_pattern)"
            exit 1
            ;;
    esac

    fail_unless_nubmer "$pid" "Fail to get one valid pid on $server_ip:$server_port"
    echo "======================== Monitor process($pid) on $server_ip:$server_port"

    ssh_mkdir_command="$ssh_connect mkdir -p $HISTORY_DIR"
    $ssh_mkdir_command

    if $UPDATE_SERVER_SCRIPT; then
        echo "upload monitor_process.sh to $HISTORY_DIR"
        scp -P "$server_port" -o "StrictHostKeyChecking=no" "$monitor_process_path" \
            "$ssh_username@$server_ip:$monitor_process_path"
    else
        echo "Skip upload monitor_process.sh"
    fi

    echo "Run $monitor_process_path $HISTORY_DIR $pid"
    $ssh_connect bash -e "$monitor_process_path" "$HISTORY_DIR" "$pid"
}
################################################################################################
trap shell_exit SIGHUP SIGINT SIGTERM 0

source_string "$env_parameters"

# set default variables
[ -n "$HISTORY_DIR" ] || HISTORY_DIR="/opt/monitor_process"
[ -n "$SHOW_OS_UTILIZATION" ] || SHOW_OS_UTILIZATION=true
[ -n "$UPDATE_SERVER_SCRIPT" ] || UPDATE_SERVER_SCRIPT=true

process_list=$(string_strip_comments "$process_list")
monitor_process_path="/tmp/monitor_process.sh"

# Input Parameters check
check_list_fields "IP:TCP_PORT:STRING:STRING:STRING" "$process_list"

generate_monitor_script
IFS=$'\n'
for process in ${process_list[*]}; do
    unset IFS

    IFS=:
    item=($process)
    unset IFS

    server_ip=${item[0]}
    server_port=${item[1]}
    ssh_username=${item[2]}
    process_pattern=${item[3]}
    process_id=${item[4]}

    monitor_remote_process "$server_ip" "$server_port" "$ssh_username" "$process_pattern" "$process_id"
done
## File : monitor_remote_process.sh ends
