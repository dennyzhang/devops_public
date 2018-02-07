#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
## https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : linux_apply_cookbook.sh
## Author : Denny <contact@dennyzhang.com>
## Description :
## --
## Created : <2016-04-20>
## Updated: Time-stamp: <2017-09-04 18:54:42>
################################################################################################
. /etc/profile
[ -n "$DOWNLOAD_TAG_NAME" ] || export DOWNLOAD_TAG_NAME="tag_v6"
export DOWNLOAD_PREFIX="https://raw.githubusercontent.com/DennyZhang/devops_public/${DOWNLOAD_TAG_NAME}"
if [ ! -f /var/lib/devops/refresh_common_library.sh ]; then
    [ -d /var/lib/devops/ ] || (sudo mkdir -p  /var/lib/devops/ && sudo chmod 777 /var/lib/devops)
    wget -O /var/lib/devops/refresh_common_library.sh "$DOWNLOAD_PREFIX/common_library/refresh_common_library.sh"
    chmod 777 /var/lib/devops/refresh_common_library.sh
fi
bash /var/lib/devops/refresh_common_library.sh "3536991806" "/var/lib/devops/devops_common_library.sh" \
     "${DOWNLOAD_PREFIX}/common_library/devops_common_library.sh"
. /var/lib/devops/devops_common_library.sh
# TODO: better way to update this bash common library
################################################################################################
# Sample:
#       docker run -t -d --privileged -h mytest --name my-test -p 5122:22 denny/sshd:v1 /usr/sbin/sshd -D
#       docker exec -it my-test bash
#           export branch_name="DOCS-227-general-security"
#           export git_repo_url="git@github.com:DennyZhang/chef_community_cookbooks.git"
#           export chef_json="{\"run_list\": [\"recipe[general_security]\"], \"general_security\": {\"ssh_disable_passwd_login\": \"true\", \"ssh_disable_root_login\": \"false\"}}"
#           apt-get install -y curl
#           curl -o /tmp/linux_apply_cookbook.sh https://raw.githubusercontent.com/DennyZhang/devops_public/master/chef/linux_apply_cookbook.sh
#           bash -xe /tmp/linux_apply_cookbook.sh
################################################################################################
function basic_setup() {
    if ! which curl 1>/dev/null 2>&1; then
        echo "Install curl package"
        apt-get install -y curl
    fi

    if [ ! -f /root/git_update.sh ]; then
        echo "Basic setup and installation for chef deployment"
        file_url="${DOWNLOAD_PREFIX}/chef/devops_provision_os.sh"
        curl -o /tmp/devops_provision_os.sh "$file_url"
        bash -e /tmp/devops_provision_os.sh
    fi
}

function chef_configuration() {
    local branch_name=${1?}
    local working_dir=${2?}
    local git_repo_url=${3?}
    local chef_json=${4?}

    git_repo=${git_repo_url%.git}
    git_repo=${git_repo##*\/}

    chef_client_rb="$working_dir/client.rb"
    chef_json_file="$working_dir/client.json"

    echo "Generate chef configuration files: $chef_client_rb, $chef_json_file"
    cat > "$chef_client_rb" <<EOF
file_cache_path "/var/chef/cache"
cookbook_path ["$working_dir/$branch_name/$git_repo/cookbooks","$working_dir/$branch_name/$git_repo/community_cookbooks"]
EOF

    echo "$chef_json" > "$chef_json_file"
}

################################################################################################
fail_unless_root
fail_unless_os "ubuntu"
ensure_variable_isset "branch_name must be set" "$branch_name"
ensure_variable_isset "git_repo_url must be set" "$git_repo_url"
ensure_variable_isset "chef_json must be set" "$chef_json"

[ -n "$working_dir" ] || working_dir="/root/devops"

# TODO: combine current scripts with devops_provision_os.sh
basic_setup
git_update_code "$branch_name" "$working_dir" "$git_repo_url" "$git_repo"
chef_configuration "$branch_name" "$working_dir" "$git_repo_url" "$chef_json" "$git_repo"

echo "Run Chef update: chef-client --config $working_dir/client.rb -j $working_dir/client.json --local-mode"
chef-client --config "$working_dir/client.rb" -j "$working_dir/client.json" --local-mode

echo "Action Done"
## File : linux_apply_cookbook.sh ends
