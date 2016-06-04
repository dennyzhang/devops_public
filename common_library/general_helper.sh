#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : general_helper.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
## --
## Created : <2016-01-08>
## Updated: Time-stamp: <2016-06-04 17:25:36>
##-------------------------------------------------------------------
function log() {
    local msg=$*
    date_timestamp=$(date +['%Y-%m-%d %H:%M:%S'])
    echo -ne "$date_timestamp $msg\n"

    if [ -n "$LOG_FILE" ]; then
        echo -ne "$date_timestamp $msg\n" >> "$LOG_FILE"
    fi
}

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
    sudo touch /tmp/deploy_cluster_bindhosts.sh
    sudo chmod 777 /tmp/deploy_cluster_bindhosts.sh
    cat << "EOF" > /tmp/deploy_cluster_bindhosts.sh
#!/bin/bash -xe

hosts_list=${1?}
cp /etc/hosts /tmp/hosts

hosts_arr=(${hosts_list//,/ })

for host in ${hosts_arr[@]}
do
    host_split=(${host//:/ })
    ip=${host_split[0]}
    domain=${host_split[1]}
    grep ${domain} /tmp/hosts && sed -i "/${domain}/c\\${ip}    ${domain}" /tmp/hosts ||  echo "${ip}    ${domain}" >> /tmp/hosts
done

if [ "$(cat /tmp/hosts)" != "$(cat /etc/hosts)" ]; then
    cp -f /tmp/hosts /etc/hosts
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

function inject_ssh_key() {
    local ssh_private_key=${1:-""}
    local ssh_key_file=${2:-""}

    if [ -z "$ssh_private_key" ] && [ ! -f "$ssh_key_file" ]; then
        echo "ERROR: wrong input: ssh_private_key parameter must be given"
        exit 1
    fi

    if [ -n "$ssh_private_key" ]; then
        mkdir -p /var/lib/jenkins/.ssh/
        if [ -f "$ssh_key_file" ]; then
            chmod 777 "$ssh_key_file"
        fi
        echo "$ssh_private_key" > "$ssh_key_file"
        chmod 400 "$ssh_key_file"
    fi
}

function parse_parameter_chef_json() {
    local chef_json=${1:-""}
    # chef_json parameters
    if [ -n "${chef_json}" ]; then
        chef_json=$(string_strip_comments "$chef_json")
        chef_json="$chef_json"
        chef_json=${chef_json/#\{/}
        chef_json=${chef_json/%\}/}
    fi
    echo "$chef_json"
}

function chef_deploy() {
    # TODO: Sample
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
    $ssh_command
    log "Deploy $server end"
}
######################################################################
## File : general_helper.sh ends
