#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2015 DennyZhang.com
## File : bash_common_library.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
## --
## Created : <2016-01-08>
## Updated: Time-stamp: <2016-04-07 08:45:46>
##-------------------------------------------------------------------
########################### Check Parameters ########################
function ensure_variable_isset() {
    message=${1?"parameter name should be given"}    
    var=${2:-''}
    # TODO support sudo, without source
    if [ -z "$var" ]; then
        echo "Error: Certain variable($message) is not set"
        exit 1
    fi
}

function ensure_is_root() {
    # Make sure only root can run our script
    if [[ $EUID -ne 0 ]]; then
        echo "Error: This script must be run as root." 1>&2
        exit 1
    fi
}

########################### String Manipulation ########################
function remove_hardline() {
    # handle \n\r of Windows OS
    local str=$*
    echo "$str" | tr -d '\r'
}

############################ git ################################
function current_git_sha() {
    set -e
    local src_dir=${1?}
    cd $src_dir
    sha=$(git log -n 1 | head -n 1 | grep commit | head -n 1 | awk -F' ' '{print $2}')
    echo $sha
}

function git_update_code() {
    set -e
    local git_repo=${1?}
    local branch_name=${2?}
    local working_dir=${3?}
    local git_repo_url=${4?}
    local git_pull_outside=${5:-"no"}

    echo "Git update code for '$git_repo_url' to $working_dir, branch_name: $branch_name"
    # checkout code, if absent
    if [ ! -d $working_dir/$branch_name/$git_repo ]; then
        mkdir -p $working_dir/$branch_name
        cd $working_dir/$branch_name
        git clone --depth 1 $git_repo_url --branch $branch_name --single-branch
    else
        cd $working_dir/$branch_name/$git_repo
        git config remote.origin.url $git_repo_url
        # add retry for network turbulence
        git pull origin $branch_name || (sleep 2 && git pull origin $branch_name)
    fi

    cd $working_dir/$branch_name/$git_repo
    git checkout $branch_name
    git reset --hard
}

############################ network ################################
function check_url_200() {
    url=${1?}
    if curl -I $url | grep "HTTP/1.* 200 OK" 2>/dev/null 1>/dev/null; then
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
        for ((i=1; i <= $max_retries_count; i++))
        do
            # get http_code
            curl -I -s --connect-timeout $timeout -m $maxtime $website | tee website_tmp.txt
            ret=`cat website_tmp.txt | grep -q "200 OK" && echo yes || echo no`
            if [ "X$ret" = "Xyes" ]; then
                log "$website connect succeed"
                break
            fi
            if [ $i -eq $max_retries_count ];then
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
############################ general ################################
function list_strip_comments() {
    my_list=${1?}
    my_list=$(echo "$my_list" | grep -v '^#')
    echo "$my_list"
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

function log() {
    local msg=$*
    echo -ne `date +['%Y-%m-%d %H:%M:%S']`" $msg\n"
}

function is_port_listening()
{
    port=${1?}
    lsof -i tcp:$port | grep LISTEN 1>/dev/null
}

function ssh_apt_update() {
    set +e
    # Sample: ssh_apt_update "ssh -i $ssh_key_file -p $ssh_port -o StrictHostKeyChecking=no root@$ssh_server_ip"
    ssh_command=${1?}
    echo "Run apt-get -y update"
    apt_get_output=$($ssh_command apt-get -y update)
    if echo "$apt_get_output" | "Hash Sum mismatch" 2>&1 2>/dev/null; then
        echo "apt-get update fail with complain of 'Hash Sum mismatch'"
        echo "rm -rf /var/lib/apt/lists/*"
        $ssh_command "rm -rf /var/lib/apt/lists/*"
        echo "Re-run apt-get -y update"
        $ssh_command "apt-get -y update"
    fi
    set -e
}

######################################################################
## File : bash_common_library.sh ends
