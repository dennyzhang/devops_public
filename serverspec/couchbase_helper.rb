# -*- encoding: utf-8 -*-
#!/usr/bin/ruby
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : couchbase_helper.rb
## Author : DennyZhang.com <denny@dennyzhang.com>
## Description :
## --
## Created : <2016-05-10>
## Updated: Time-stamp: <2016-06-04 09:56:21>
##-------------------------------------------------------------------
################################################################################
require 'socket'
require 'serverspec'
require 'open3'

# Required by serverspec
set :backend, :exec

# couchbase
def couchbase_general_check(tcp_port)
  # Basic verification logic for couchbase installation
  describe port(tcp_port) do
    it { should be_listening }
  end

  describe service('couchbase-server') do
    it { should be_running }
  end

  describe command('grep version /opt/couchbase/etc/runtime.ini') do
    its(:stdout) { should contain 'version = 4.1.0' }
  end
end

def verify_cb_node_count(server_ip, tcp_port, expected_node_count)
  cb_username = 'Administrator'
  cb_password = 'password1234'
  check_command = "curl -u #{cb_username}:#{cb_password} " \
                  "#{server_ip}:#{tcp_port}/pools/default | " \
                  "grep -o 'otpNode' | wc -l"

  describe command(check_command) do
    its(:stdout) { should eq "#{expected_node_count}\n" }
  end
end

def verify_cb_node_in_cluster(server_ip, node_ip)
  # Confirm node_ip is in the couchbase cluster of server_ip
  # TODO: make code more general
  describe command('/opt/mdm/bin/couchbase_cluster.sh node_in_cluster ' \
                   "#{server_ip} #{node_ip}") do
    its(:exit_status) { should eq 0 }
  end
end
#############################################################################
## File : couchbase_helper.rb ends
