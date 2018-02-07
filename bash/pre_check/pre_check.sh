#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
## https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : pre_check.sh
## Author : Denny <contact@dennyzhang.com>
## Description :
## Sample:
## --
## Created : <2016-06-12>
## Updated: Time-stamp: <2018-01-29 16:08:48>
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
################################################################################################
# TODO: better way to update this bash common library
function install_serverspec() {
    if ! sudo gem list | grep serverspec 2>/dev/null 1>/dev/null; then
        sudo gem install serverspec
    fi

    os_version=$(os_release)
    if [ "$os_version" == "ubuntu" ]; then
        if ! sudo dpkg -l rake 2>/dev/null 1>/dev/null; then
            sudo apt-get install -y rake
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
################################################################################
function shell_exit() {
    errcode=$?
    if [ $? -eq 0 ]; then
        log "Backup operation is done"
        log "########## Backup operation is done #############################"
        echo "State: DONE Timestamp: $(current_time)" >> "$STATUS_FILE"
    else
        log "ERROR: Backup operation fail"
        log "########## ERROR: Backup operation fail #########################"
        echo "State: FAILED Timestamp: $(current_time)" >> "$STATUS_FILE"
        # TODO: send out email
        exit 1
    fi
    exit $errcode
}

trap shell_exit SIGHUP SIGINT SIGTERM 0

# fail_unless_os "ubuntu|redhat/centos/osx"
fail_unless_os "ubuntu"
install_package_list "wget,curl,lsof"
install_ruby "2.1.8" # TODO: install ruby

if [ -z "$working_dir" ]; then
    working_dir="/root/pre_check"
fi
mkdir -p $working_dir/spec/localhost
cd $working_dir

# sudo /usr/sbin/locale-gen --lang en_US.UTF-8
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

install_serverspec
setup_serverspec $working_dir

# TODO: read testcase from cfg file

# TODO: built-in support: OS version, network check, memory and cpu check, free disk check

cat > spec/localhost/sample_spec.rb <<EOF
require 'spec_helper'

$test_spec
EOF

echo "Perform serverspec checks: $working_dir/spec/localhost/sample_spec.rb"
rake spec -v
## File: pre_check.sh ends
