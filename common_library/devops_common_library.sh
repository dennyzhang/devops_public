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
## Updated: Time-stamp: <2016-05-03 16:20:23>
##-------------------------------------------------------------------
########################### Section: Parameters & Status ########################
function fail_unless_root() {
    # Make sure only root can run our script
    if [[ $EUID -ne 0 ]]; then
        echo "Error: This script must be run as root." 1>&2
        exit 1
    fi
}

function fail_unless_os() {
    local supported_os=${1?}
    current_os=$(os_release)
    if [[ "$supported_os" != *"$current_os"* ]]; then
        echo "Error: supported OS are $supported_os, while current OS is $current_os" 1>&2
        exit 1
    fi
}

function fail_unless_nubmer() {
    local var=${1?}
    local message=${2:-""}

    re='^[0-9]+$'
    if ! [[ $var =~ $re ]] ; then
        echo "Error: $var is not a valid number.${message}" 1>&2
        exit 1
    fi
}

function ensure_variable_isset() {
    # Sample: ensure_variable_isset "chef_client_rb must be set" "$chef_client_rb"
    message=${1?"parameter name should be given"}
    var=${2:-''}
    # TODO support sudo, without source
    if [ -z "$var" ]; then
        echo "Error: Certain variable($message) is not set" 1>&2
        exit 1
    fi
}

function exit_if_error() {
    if [ $? -ne 0 ];then
        exit 1
    fi
}

function log() {
    local msg=$*
    date_timestamp=$(date +['%Y-%m-%d %H:%M:%S'])
    echo -ne "$date_timestamp $msg\n"

    if [ -n "$LOG_FILE" ]; then
        echo -ne "$date_timestamp $msg\n" >> "$LOG_FILE"
    fi
}

########################### Section: String Manipulation ########################
function remove_hardline() {
    # handle \n\r of Windows OS
    local str=$*
    echo "$str" | tr -d '\r'
}

function string_strip_whitespace() {
    # handle \n\r of Windows OS
    local str=$*
    str=$(echo "${str}" |sed -e 's/^[ \t]*//g')
    str=$(echo "${str}" |sed -e 's/[ \t]*$//g')
    echo "$str"
}

function string_strip_comments() {
    my_str=${1?}
    my_str=$(echo "$my_str" | grep -v '^ *#')
    echo "$my_str"
}
############################ Section: git ################################
function current_git_sha() {
    set -e
    local src_dir=${1?}
    cd "$src_dir"
    sha=$(git log -n 1 | head -n 1 | grep commit | head -n 1 | awk -F' ' '{print $2}')
    echo "$sha"
}

function git_log() {
    local code_dir=${1?}
    local tail_count=${2:-"10"}
    cd "$code_dir"
    command="git log -n $tail_count --pretty=format:\"%h - %an, %ar : %s\""
    echo -e "\n\nShow latest git commits: $command"
    eval "$command"
}

function git_update_code() {
    set -e
    local branch_name=${1?}
    local working_dir=${2?}
    local git_repo_url=${3?}

    local git_repo
    git_repo=$(echo "${git_repo_url%.git}" | awk -F '/' '{print $2}')

    local code_dir="$working_dir/$branch_name/$git_repo"
    echo "Git update code for $git_repo_url to $code_dir"
    # checkout code, if absent
    if [ ! -d "$working_dir/$branch_name/$git_repo" ]; then
        mkdir -p "$working_dir/$branch_name"
        cd "$working_dir/$branch_name"
        git clone --depth 1 "$git_repo_url" --branch "$branch_name" --single-branch
    else
        cd "$code_dir"
        git config remote.origin.url "$git_repo_url"
        # add retry for network turbulence
        git pull origin "$branch_name" || (sleep 2 && git pull origin "$branch_name")
    fi

    cd "$code_dir"
    git checkout "$branch_name"
    git reset --hard
}

############################ Section: network ################################
function is_port_listening()
{
    port=${1?}
    lsof -i "tcp:${port}" | grep LISTEN 1>/dev/null
}

function check_ssh_available() {
    # Sample: if [ "x$(check_ssh_available $server_ip $server_port)" = "xyes" ] ...
    local server_ip=${1?}
    local server_port=${2?}
    nc -w 1 "$server_ip" "$server_port" 1>/dev/null 2>&1 && echo yes || echo no
}

function check_url_200() {
    url=${1?}
    if curl -I "$url" | grep "HTTP/1.* 200 OK" 2>/dev/null 1>/dev/null; then
        echo "yes"
    else
        echo "no"
    fi
}

function check_network()
{
    # The maximum number of trying to connect website
    local max_retries_count=${1:-3}

    # Check website whether can connect, multiple websites, separated by spaces
    local website_list=${2:-"https://bitbucket.org/"}

    # Connect timeout
    local timeout=7

    # The maximum allowable time data transmission
    local maxtime=10

    # If the website cannnt connect,will sleep several second
    local sleep_time=5

    # If any one website cannt connect,the flag value is false, otherwise is true.
    local check_flag=true

    log "max_retries_count=$max_retries_count, website_list=$website_list"

    connect_failed_website=""
    for website in ${website_list[*]}
    do
        for ((i=1; i <=max_retries_count; i++))
        do
            # get http_code
            curl -I -s --connect-timeout $timeout -m $maxtime "$website" | tee website_tmp.txt
            ret=$(grep "200 OK" website_tmp.txt && echo yes || echo no)
            if [ "X$ret" = "Xyes" ]; then
                log "$website connect succeed"
                break
            fi
            if [ "$i" = "$max_retries_count" ];then
                log "$website connect failed"
                log "The curl result:"
                cat website_tmp.txt
                connect_failed_website="${connect_failed_website} ${website}"
                check_flag=false
                break
            fi
            sleep $sleep_time
        done
    done
    log "========== connect_failed_website= ${connect_failed_website}=========="
    if ! $check_flag ;then
        exit 1
    fi
}
############################ Section: docker ################################
function guess_docker_daemon_ip() {
    local docker_daemon_ip=""
    local lists
    lists="172.18.42.1 172.17.42.1 172.18.0.1 172.17.0.1 192.168.50.10"
    lists=($lists)
    for ip in ${lists[*]}; do
        if ping -c3 "$ip" 2>/dev/null 1>/dev/null; then
            docker_daemon_ip=$ip
            break
        fi
    done
    echo "$docker_daemon_ip"
}

function install_docker() {
    local os_release_name
    if ! which docker 1>/dev/null 2>/dev/null; then
        os_release_name=$(os_release)
        if [ "$os_release_name" == "centos" ]; then
            log "yum install -y docker-io"
            yum install -y http://mirrors.yun-idc.com/epel/6/i386/epel-release-6-8.noarch.rpm
            yum install -y docker-io
            service docker start
            chkconfig docker on
        else
            log "Install docker: wget -qO- https://get.docker.com/ | sh"
            wget -qO- https://get.docker.com/ | sh
        fi
    else
        log "docker service exists, skip installation"
    fi
}

function create_enough_loop_device() {
    local file_count=${1:-50}
    # Docker start may fail, due to no available loopback devices
    for((i=0; i<file_count; i++)); do
        if [ ! -b /dev/loop$i ]; then
            echo "mknod -m0660 /dev/loop$i b 7 $i"
            mknod -m0660 /dev/loop$i b 7 $i
        fi
    done
}

function is_container_running(){
    local container_name=${1?}
    if docker ps -a | grep "$container_name" 1>/dev/null 2>/dev/null; then
        if docker ps | grep "$container_name" 1>/dev/null 2>/dev/null; then
            echo "running"
        else
            echo "dead"
        fi
    else
        echo "none"
    fi
}
############################ Section: general ################################
function generate_checksum() {
    local dst_dir=${1?}
    cd "$dst_dir"
    current_filename=$(basename "${0}")
    tmp_file="/tmp/${current_filename}_$$"
    > "$tmp_file"
    for f in *; do
        if [ "$f" != "checksum.txt" ]; then
            cksum "$f" >> "$tmp_file"
        fi
    done
    mv "$tmp_file" checksum.txt
}

function os_release() {
    set -e
    distributor_id=$(lsb_release -a 2>/dev/null | grep 'Distributor ID' | awk -F":\t" '{print $2}')
    if [ "$distributor_id" == "RedHatEnterpriseServer" ]; then
        echo "redhat"
    elif [ "$distributor_id" == "Ubuntu" ]; then
        echo "ubuntu"
    else
        if grep CentOS /etc/issue 1>/dev/null 2>/dev/null; then
            echo "centos"
        else
            if uname -a | grep '^Darwin' 1>/dev/null 2>/dev/null; then
                echo "osx"
            else
                echo "ERROR: Not supported OS"
            fi
        fi
    fi
}

function ssh_apt_update() {
    set +e
    # Sample: ssh_apt_update "ssh -i $ssh_key_file -p $ssh_port -o StrictHostKeyChecking=no root@$ssh_server_ip"
    local ssh_command=${1?}
    echo "Run apt-get -y update"
    apt_get_output=$($ssh_command apt-get -y update)
    if echo "$apt_get_output" | "Hash Sum mismatch" 1>/dev/null 2>&1; then
        echo "apt-get update fail with complain of 'Hash Sum mismatch'"
        echo "rm -rf /var/lib/apt/lists/*"
        $ssh_command "rm -rf /var/lib/apt/lists/*"
        echo "Re-run apt-get -y update"
        $ssh_command "apt-get -y update"
    fi
    set -e
}

function update_system() {
    local os_release_name
    os_release_name=$(os_release)
    if [ "$os_release_name" == "ubuntu" ]; then
        log "apt-get -y update"
        rm -rf /var/lib/apt/lists/*
        apt-get -y update
    fi

    if [ "$os_release_name" == "redhat" ] || [ "$os_release_name" == "centos" ]; then
        yum -y update
    fi
}
######################################################################
## File : devops_common_library.sh ends
