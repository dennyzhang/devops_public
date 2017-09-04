#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : general_helper.sh
## Author : Denny <contact@dennyzhang.com>
## Description :
## --
## Created : <2016-01-08>
## Updated: Time-stamp: <2017-09-04 18:54:41>
##-------------------------------------------------------------------
function log() {
    # log message to both stdout and logfile on condition
    local msg=$*
    date_timestamp=$(date +['%Y-%m-%d %H:%M:%S'])
    echo -ne "$date_timestamp $msg\n"

    if [ -n "$LOG_FILE" ]; then
        echo -ne "$date_timestamp $msg\n" >> "$LOG_FILE"
    fi
}

################################################################################
function generate_dir_checksum() {
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

function inject_ssh_key() {
    local ssh_private_key=${1:-""}
    local ssh_key_file=${2:-""}
    local ssh_dir=${3:-"/var/lib/jenkins/.ssh"}

    if [ -z "$ssh_private_key" ] && [ ! -f "$ssh_key_file" ]; then
        echo "ERROR: wrong input: ssh_private_key parameter must be given"
        exit 1
    fi

    if [ -n "$ssh_private_key" ]; then
        mkdir -p "$ssh_dir"
        if [ -f "$ssh_key_file" ]; then
            chmod 777 "$ssh_key_file"
        fi
        echo "$ssh_private_key" > "$ssh_key_file"
        chmod 400 "$ssh_key_file"
    fi
}

function os_release() {
    # Sample: 
    # os_release -> ubuntu
    # os_release true -> ubuntu-14.04
    local show_version=${1:-"false"}
    set -e
    os_type=""
    if which lsb_release 1>/dev/null 2>/dev/null; then
        distributor_id=$(lsb_release -a 2>/dev/null | grep 'Distributor ID' | awk -F":\t" '{print $2}')
        if [ "$distributor_id" == "RedHatEnterpriseServer" ]; then
            os_type="redhat"
        fi

        if [ "$distributor_id" == "Ubuntu" ]; then
            os_type="ubuntu"
        fi
    fi

    if grep CentOS /etc/issue 1>/dev/null 2>/dev/null; then
        os_type="centos"
    fi

    if grep Debian /etc/issue 1>/dev/null 2>/dev/null; then
        os_type="debian"
    fi

    if uname -a | grep '^Darwin' 1>/dev/null 2>/dev/null; then
        os_type="osx"
    fi

    if [ -z "$os_type" ]; then
        echo"ERROR: Not supported OS"
        exit 1
    fi

    if [ "$show_version" = "true" ]; then
        release_version=$(lsb_release -a 2>/dev/null | grep 'Release' | awk -F":\t" '{print $2}')
        echo "${os_type}-${release_version}"
    else
        echo "$os_type"
    fi
}

######################################################################
function bindhosts() {
    # TODO: improve code quality
    echo "Start to bind cluster hosts"
    local server_list=${1?}
    local ssh_key_file=${2?}

    local hosts_list=""
    local ssh_args="-i $ssh_key_file -o StrictHostKeyChecking=no"

    for server in ${server_list}
    do
        server_split=(${server//:/ })
        ssh_server_ip=${server_split[0]}
        ssh_port=${server_split[1]}
        ssh_command="ssh $ssh_args -p $ssh_port root@$ssh_server_ip ifconfig eth0 | grep 'inet addr:' | awk '{print \$2}' | cut -c 6-"
        ip=$(eval "$ssh_command")

        ssh_command="ssh $ssh_args -p $ssh_port root@$ssh_server_ip hostname"
        hostname=$(eval "$ssh_command")
        hosts_list="${hosts_list},${ip}:${hostname}"
    done

    # Fix acl issue
    touch /tmp/deploy_cluster_bindhosts.sh
    chmod 777 /tmp/deploy_cluster_bindhosts.sh
    cat << "EOF" > /tmp/deploy_cluster_bindhosts.sh
#!/bin/bash -xe

hosts_list=${1?}
cp /etc/hosts /root/hosts

hosts_arr=(${hosts_list//,/ })

for host in ${hosts_arr[@]}
do
    host_split=(${host//:/ })
    ip=${host_split[0]}
    domain=${host_split[1]}
    if grep "${domain}$" /root/hosts; then
       sed -i "s/.*    ${domain}$/${ip}    ${domain}/g" /root/hosts
    else
        echo "${ip}    ${domain}" >> /root/hosts
    fi
done

if [ "$(cat /root/hosts)" != "$(cat /etc/hosts)" ]; then
    cp -f /root/hosts /etc/hosts
fi

EOF

    for server in ${server_list}
    do
        server_split=(${server//:/ })
        ssh_server_ip=${server_split[0]}
        ssh_port=${server_split[1]}
        ssh_command="scp $ssh_args -P $ssh_port /tmp/deploy_cluster_bindhosts.sh root@$ssh_server_ip:/tmp/deploy_cluster_bindhosts.sh"
        $ssh_command

        ssh_command="ssh $ssh_args -p $ssh_port root@$ssh_server_ip bash -xe /tmp/deploy_cluster_bindhosts.sh $hosts_list"
        $ssh_command
    done
}

function chef_deploy() {
    # chef deploy cluster
    local server=${1?}
    local CHEF_BINARY_CMD=${2?}
    local deploy_run_list=${3?}
    local chef_json=${4?}
    local chef_client_rb=${5?}

    common_ssh_options="-i $ssh_key_file -o StrictHostKeyChecking=no "
    log "Deploy to ${server}"

    local server_split=(${server//:/ })
    local ssh_server_ip=${server_split[0]}
    local ssh_port=${server_split[1]}

    log "Prepare chef configuration"
    cat > /tmp/client.rb <<EOF
file_cache_path "/var/chef/cache"
$chef_client_rb
EOF
    echo -e "{\n\"run_list\": [${deploy_run_list}],\n$chef_json\n}" > /tmp/client.json
    
    ssh_command="scp $common_ssh_options -P $ssh_port /tmp/client.rb root@$ssh_server_ip:/root/client.rb"
    $ssh_command

    ssh_command="scp $common_ssh_options -P $ssh_port /tmp/client.json root@$ssh_server_ip:/root/client.json"
    $ssh_command

    log "Apply chef update"
    # TODO: use chef-zero, instead of chef-solo
    # ssh_command="ssh $common_ssh_options -p $ssh_port root@$ssh_server_ip $CHEF_BINARY_CMD --config /root/client.rb -j /root/client.json --local-mode"
    ssh_command="ssh $common_ssh_options -p $ssh_port root@$ssh_server_ip $CHEF_BINARY_CMD --config /root/client.rb -j /root/client.json"
    log "$ssh_command"
    $ssh_command
    log "Deploy $server end"
}

function inject_ssh_authorized_keys() {
    local ssh_email=${1?}
    local ssh_public_key=${2?}
    local ssh_authorized_key_file=${3:-"/root/.ssh/authorized_keys"}

    ssh_dir=$(dirname "$ssh_authorized_key_file")
    [ -d "$ssh_dir" ] || mkdir -p "$ssh_dir"

    log "inject ssh authorized keys to $ssh_authorized_key_file"
    if ! grep "$ssh_email" "$ssh_authorized_key_file" 1>/dev/null 2>&1; then
        echo "$ssh_public_key" >> "$ssh_authorized_key_file"
    fi
}

function download_facility() {
    local dst_file=${1:?}
    local url=${2?}
    local file_mode=${3:-"755"}
    if [ ! -f "$dst_file" ]; then
        command="wget -O $dst_file $url"
        log "$command"
        eval "$command"
        chmod "$file_mode" "$dst_file"
    fi
}

function wait_for() {
    # wait_for "service apache2 status" 3
    # wait_for "lsof -i tcp:8080" 10
    local check_command=${1?}
    local timeout_seconds=${2?}

    log "Wait for: $check_command"
    for((i=0; i<timeout_seconds; i++)); do
        if eval "$check_command"; then
            log "Action pass"
            exit 0
        fi
        sleep 1
    done

    log "Error: wait for more than $timeout_seconds seconds"
    exit 1
}
######################################################################
## File : general_helper.sh ends
