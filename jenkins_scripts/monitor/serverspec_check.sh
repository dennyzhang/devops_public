#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : serverspec_check.sh
## Author : DennyZhang.com <contact@dennyzhang.com>
## Description :
## --
## Created : <2015-07-29>
## Updated: Time-stamp: <2017-09-04 18:54:38>
##-------------------------------------------------------------------

################################################################################################
## env variables:
##      test_spec:
##          describe service('apache2') do
##           it { should be_running }
##          end
################################################################################################
. /etc/profile
[ -n "$DOWNLOAD_TAG_NAME" ] || export DOWNLOAD_TAG_NAME="tag_v6"
export DOWNLOAD_PREFIX="https://raw.githubusercontent.com/DennyZhang/devops_public/${DOWNLOAD_TAG_NAME}"
if [ ! -f /var/lib/devops/refresh_common_library.sh ]; then
    [ -d /var/lib/devops/ ] || (mkdir -p /var/lib/devops/ && chmod 777 /var/lib/devops)
    wget -O /var/lib/devops/refresh_common_library.sh "$DOWNLOAD_PREFIX/common_library/refresh_common_library.sh"
    chmod 777 /var/lib/devops/refresh_common_library.sh
fi
bash /var/lib/devops/refresh_common_library.sh "3536991806" "/var/lib/devops/devops_common_library.sh" \
     "${DOWNLOAD_PREFIX}/common_library/devops_common_library.sh"
. /var/lib/devops/devops_common_library.sh
################################################################################################
fail_unless_os "ubuntu|redhat/centos/osx/debian"
function install_serverspec() {
    if ! gem list | grep serverspec 2>/dev/null 1>/dev/null; then
        gem install serverspec
    fi

    os_version=$(os_release)
    if [ "$os_version" == "ubuntu" ]; then
        if ! dpkg -l rake 2>/dev/null 1>/dev/null; then
            apt-get install -y rake
        fi
    else
        echo "Warning: not implemented supported for OS: $os_version"
    fi
}

function setup_serverspec() {
    working_dir=${1?}
    cd "$working_dir"
    if [ ! -f spec/spec_helper.rb ]; then
        echo "Setup Serverspec Test case"
        cat > spec/spec_helper.rb <<EOF
require 'serverspec'

set :backend, :exec
EOF

        cat > Rakefile <<EOF
require 'rake'
require 'rspec/core/rake_task'

task :spec => 'spec:all'
task :default => :spec

namespace :spec do
 targets = []
 Dir.glob('./spec/*').each do |dir|
 next unless File.directory?(dir)
 target = File.basename(dir)
 target = "_#{target}" if target == "default"
 targets << target
 end

 task :all => targets
 task :default => :all

 targets.each do |target|
 original_target = target == "_default" ? target[1..-1] : target
 desc "Run serverspec tests to #{original_target}"
 RSpec::Core::RakeTask.new(target.to_sym) do |t|
 ENV['TARGET_HOST'] = original_target
 t.pattern = "spec/#{original_target}/*_spec.rb"
 end
 end
end
EOF
    fi
}


flag_file="$HOME/$JOB_NAME.flag"

function shell_exit() {
    errcode=$?
    if [ -z "$SKIP_UPDATE_FLAGFILE" ] || [ "$SKIP_UPDATE_FLAGFILE" = "false" ]; then
        if [ $errcode -eq 0 ]; then
            echo "OK" > "$flag_file"
        else
            echo "ERROR" > "$flag_file"
        fi
    fi
    exit $errcode
}

trap shell_exit SIGHUP SIGINT SIGTERM 0

#####################################################
[ -n "$working_dir" ] || working_dir="$HOME/code/$JOB_NAME"

mkdir -p "$working_dir/spec/localhost"
cd "$working_dir"

# /usr/sbin/locale-gen --lang en_US.UTF-8
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

install_serverspec
setup_serverspec "$working_dir"

cat > spec/localhost/sample_spec.rb <<EOF
require 'spec_helper'

# Check at least 2 GB free disk
describe command("[ $(df -h / | tail -n1 |awk -F' ' '{print $4}' | awk -F'G' '{print $1}' | awk -F'.' '{print $1}') -gt 2 ]") do
  its(:exit_status) { should eq 0 }
end

$test_spec
EOF

echo "Perform serverspec check: $working_dir/spec/localhost/sample_spec.rb"
rake spec -v

# # TODO: integrate below bash section into serverspec
# #$remote_list
# # 0 remote server ip
# # 1 remote server ssh port
# # 2 remote server ssh key
# # 3 command 1: "get cpu loadavg" < 20
# # 4 command 2: "get docker container number" < 15
# if [ -n "$remote_list" ]; then
#     remote_list=(${remote_list// / })

#     ssh_connect="ssh -p ${remote_list[1]} -i ${remote_list[2]} -o stricthostkeychecking=no root@${remote_list[0]}"
#     loadavg_va=$($ssh_connect "cat /proc/loadavg | awk '{print \$1}'")
#     container_num=$($ssh_connect "docker ps | sed '1d' | wc -l")

#     # compare loadavg value
#     if [ "$(echo "$loadavg_va > ${remote_list[3]}" | bc)" = "1" ]; then
#         exit 1
#     fi

#     # compare the number of containers
#     if [ "$container_num" -gt "${remote_list[4]}" ]; then
#         exit 1
#     fi
# fi
## File : serverspec_check.sh ends
