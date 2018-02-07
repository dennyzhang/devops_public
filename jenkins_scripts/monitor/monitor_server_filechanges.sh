#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : monitor_server_filechanges.sh
## Author : DennyZhang.com <contact@dennyzhang.com>
## Description :
## --
## Created : <2016-04-03>
## Updated: Time-stamp: <2017-09-04 18:54:38>
##-------------------------------------------------------------------
################################################################################################
## env variables:
##      server_list:
##         192.168.1.2:2703
##         192.168.1.3:2704
##      file_list:
##         /etc/hosts
##         /etc/profile.d
##      env_parameters:
##          export MARK_PREVIOUS_AS_TRUE=false
##          export FORCE_RESTART_INOTIFY_PROCESS=false
##          export CLEAN_START=false
##          export BACKUP_OLD_DIR=/root/monitor_backup
##          export EXIT_NODE_CONNECT_FAIL=false
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
function install_inotifywait_package() {
    local ssh_connect=${1?}

    echo "Check whether inotify utility is installed"
    if ! $ssh_connect which inotifywait 1>/dev/null 2>&1; then
        echo "Warning: inotify utility is not installed. Install it"
        $ssh_connect apt-get install -y inotify-tools
    fi
}

function get_inotifywait_command() {
    # Sample:
    # /usr/bin/inotifywait -d -m --timefmt '%Y-%m-%d %H:%M:%S' --format '%T %w %e %f' -e modify -r /etc/apt/sources.list.d /etc/hosts /tmp/hosts --outfile /root/monitor_server_filechanges.log
    # /usr/bin/inotifywait -m --timefmt '%Y-%m-%d %H:%M:%S' --format '%T %w %e %f' -e modify -r /etc/apt/sources.list.d /etc/hosts /tmp/hosts
    local ssh_connect=${1?}
    local file_list=${2?}
    local inotifywait_command="/usr/bin/inotifywait -d -m --timefmt '%Y-%m-%d %H:%M:%S' --format '%T %w %e %f' -e modify -r "
    local monitor_directories=""

    for file in $file_list; do
        if $ssh_connect [ -f "$file" -o -d "$file" ]; then
            monitor_directories="$monitor_directories $file"
        fi
    done

    if [ "$monitor_directories" = "" ]; then
        echo "ERROR: No qualified files to be monitored in $ssh_server_ip"
        has_error="1"
        return 1
    fi

    echo "$inotifywait_command $monitor_directories"
}

function start_remote_inotify_process() {
    local ssh_connect=${1?}
    local should_restart_process=${2?}

    if $ssh_connect ps -ef | grep -v grep | grep inotifywait 1>/dev/null 2>&1; then
        echo "inotifywait process is already running"
        if [ "$should_restart_process" = "true" ]; then
            echo "Kill existing inotify process"
            command="killall inotifywait"
            $ssh_connect "$command"
        else
            return 0
        fi
    fi

    if inotifywait_command=$(get_inotifywait_command "$ssh_connect" "$file_list"); then
        local command="$ssh_connect \"$inotifywait_command --outfile $log_file\""
        echo "Run $command"
        eval "$command"
    fi
}

function check_server_filechanges() {
    local ssh_connect=${1?}

    echo "Check whether monitored files  have been changed"
    file_size=$($ssh_connect stat -c %s "$log_file")
    if [ "$file_size" != "0" ]; then
        echo "ERROR: $log_file is not empty, which indicates files changed"
        echo -e "\n============== File Change List =============="
        $ssh_connect cat "$log_file"
        has_error="1"
    else
        echo "No monitored file has been changed so far"
    fi

    show_detail_changeset "$ssh_connect" "$file_list" "$BACKUP_OLD_DIR"
    echo -e "\n=============================================="
}

function copy_files(){
    local ssh_connect=${1?}
    local file_list=${2?}
    local current_backup_dir=${3?}
    $ssh_connect "mkdir -p $current_backup_dir"
    echo "Copy files to $current_backup_dir"
    IFS=$'\n'
    for t_file in ${file_list[*]}; do
        unset IFS
        if $ssh_connect [ -f "$t_file" -o -d "$t_file" ]; then
            # copy files while keeping directory hierarchy
            dir_name=$(dirname "$t_file")
            $ssh_connect "mkdir -p ${current_backup_dir}${dir_name}/"
            $ssh_connect "cp -Lr $t_file ${current_backup_dir}${dir_name}/"
        fi
    done
}

function show_detail_changeset() {
    local ssh_connect=${1?}
    local file_list=${2?}
    local target_dir=${3?}

    # TODO: defensive coding
    previous_backup_dir=$($ssh_connect "ls -1t $target_dir | head -n1")
    msg="\n============== Show Detail ChangeSet ==============\n"
    IFS=$'\n'
    for t_file in ${file_list[*]}; do
        unset IFS
        if $ssh_connect [ -f "$t_file" -o -d "$t_file" ]; then
            dir_name=$(dirname "$t_file")
            command="diff -r $t_file $target_dir/${previous_backup_dir}$t_file"
            if ! output=$($ssh_connect "$command"); then
                echo -e "${msg}${command}\n${output}\n"
                msg=""
            fi
        fi
    done
}

previous_filelist_file="$HOME/previous_filelist_$JOB_NAME.flag"

function shell_exit() {
    errcode=$?
    echo "$file_list" > "$previous_filelist_file"
    exit $errcode
}
################################################################################################
trap shell_exit SIGHUP SIGINT SIGTERM 0
source_string "$env_parameters"

# fail_unless_os "ubuntu/redhat/centos"

[ -n "$ssh_key_file" ] || export ssh_key_file="$HOME/.ssh/id_rsa"
[ -n "$EXIT_NODE_CONNECT_FAIL" ] || export EXIT_NODE_CONNECT_FAIL=false
[ -n "$BACKUP_OLD_DIR" ] || export BACKUP_OLD_DIR=/root/monitor_backup
[ -n "$MARK_PREVIOUS_AS_TRUE" ] || export MARK_PREVIOUS_AS_TRUE=false
[ -n "$CLEAN_START" ] || export CLEAN_START=false
[ -n "$FORCE_RESTART_INOTIFY_PROCESS" ] || export FORCE_RESTART_INOTIFY_PROCESS=false

CURRENT_BACKUP_DIR="$BACKUP_OLD_DIR/$(date +'%Y-%m-%d_%H-%M-%S')"
export has_error="0"
log_file="/root/monitor_server_filechanges.log"

server_list=$(string_strip_comments "$server_list")
server_list=$(string_strip_whitespace "$server_list")

file_list=$(string_strip_comments "$file_list")
file_list=$(string_strip_whitespace "$file_list")

# Input Parameters check
verify_comon_jenkins_parameters

# TODO: From our test, inotifywait may fail to monitor files, which has been changed by vim

# restart inotify process, if file list has been changed
if [ -f "$previous_filelist_file" ]; then
    previous_filelist=$(cat "$previous_filelist_file")
    if [ "$previous_filelist" != "$file_list" ] && \
           [ "$FORCE_RESTART_INOTIFY_PROCESS" = "false" ]; then
        FORCE_RESTART_INOTIFY_PROCESS=true
    fi
fi

has_error="0"

if [ "$CLEAN_START" = "true" ]; then
    echo "Clean up files to have a clean start"
    MARK_PREVIOUS_AS_TRUE=true
    FORCE_RESTART_INOTIFY_PROCESS=true
    rm -rf "$previous_filelist_file"
    for server in ${server_list}; do
        server_split=(${server//:/ })
        ssh_server_ip=${server_split[0]}
        ssh_port=${server_split[1]}
        ssh_username=${server_split[2]}
        [ -n "$ssh_username" ] || ssh_username="root"
        ssh_connect="ssh -i $ssh_key_file -p $ssh_port -o StrictHostKeyChecking=no $ssh_username@$ssh_server_ip"
        $ssh_connect rm -rf "$BACKUP_OLD_DIR"
    done
fi

# make initial backup
for server in ${server_list}; do
    server_split=(${server//:/ })
    ssh_server_ip=${server_split[0]}
    ssh_port=${server_split[1]}
    ssh_username=${server_split[2]}
    [ -n "$ssh_username" ] || ssh_username="root"

    ssh_connect="ssh -i $ssh_key_file -p $ssh_port -o StrictHostKeyChecking=no $ssh_username@$ssh_server_ip"
    if $ssh_connect [ ! -f "$log_file" ]; then
        echo -e "\nMake Initial Backup on $server"
        copy_files "$ssh_connect" "$file_list" "$CURRENT_BACKUP_DIR"
    fi
done

# check files
for server in ${server_list}; do
    server_split=(${server//:/ })
    ssh_server_ip=${server_split[0]}
    ssh_port=${server_split[1]}
    ssh_username=${server_split[2]}
    [ -n "$ssh_username" ] || ssh_username="root"

    echo -e "\n============== Check Node ${ssh_server_ip}:${ssh_port} for file changes =============="
    ssh_connect="ssh -i $ssh_key_file -p $ssh_port -o StrictHostKeyChecking=no $ssh_username@$ssh_server_ip"
    install_inotifywait_package  "$ssh_connect"
    start_remote_inotify_process "$ssh_connect" "$FORCE_RESTART_INOTIFY_PROCESS"
    if [ "$MARK_PREVIOUS_AS_TRUE" = "true" ]; then
        $ssh_connect truncate --size=0 "$log_file"
        copy_files "$ssh_connect" "$file_list" "$CURRENT_BACKUP_DIR"
    else
        check_server_filechanges "$ssh_connect"        
    fi
done

# quit with exit code restored
if [ "$has_error" = "1" ]; then
    exit 1
fi
## File : monitor_server_filechanges.sh ends
