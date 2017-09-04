# -*- encoding: utf-8 -*-

##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : db_helper.rb
## Author : DennyZhang.com <contact@dennyzhang.com>
## Description :
## --
## Created : <2016-05-10>
## Updated: Time-stamp: <2017-09-04 18:55:45>
##-------------------------------------------------------------------
require 'socket'
require 'serverspec'
require 'open3'

# Required by serverspec
set :backend, :exec

################################################################################
def elasticsearch_general_check(es_port, cmd_pattern, es_version, es_host)
  # Basic verification logic for elasticsearch installation
  describe command('/usr/share/elasticsearch/bin/elasticsearch --version') do
    its(:stdout) { should contain "Version: #{es_version}" }
  end

  describe service('elasticsearch') do
    it { should be_running }
  end

  describe port(es_port) do
    it { should be_listening }
  end

  es_pidfile = '/var/run/elasticsearch/elasticsearch.pid'
  # TODO: dependes on general_helper.rb
  verify_process_cmdline_by_pidfile(es_pidfile, cmd_pattern)

  return unless es_host != ''
  describe command("curl -XGET http://#{es_host}:#{es_port}") do
    its(:stdout) { should contain es_version.to_s }
  end
end

def verify_es_node_count(server_ip, tcp_port, expected_node_count)
  describe command("curl '#{server_ip}:#{tcp_port}/_cat/nodes' | wc -l") do
    its(:stdout) { should eq "#{expected_node_count}\n" }
  end
end

def verify_es_cluster_health(server_ip, es_port)
  describe command("curl -XGET http://#{server_ip}:#{es_port}" \
                   '/_cluster/health?pretty') do
    its(:stdout) { should contain '"status" : "green"' }
  end
end
################################################################################

# couchbase
def couchbase_general_check(tcp_port, cb_version)
  # Basic verification logic for couchbase installation
  describe port(tcp_port) do
    it { should be_listening }
  end

  describe service('couchbase-server') do
    it { should be_running }
  end

  describe command('grep version /opt/couchbase/etc/runtime.ini') do
    its(:stdout) { should contain "version = #{cb_version}" }
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
  describe command('/opt/devops/bin/couchbase_cluster.sh node_in_cluster ' \
                   "#{server_ip} #{node_ip}") do
    its(:exit_status) { should eq 0 }
  end
end
#############################################################################
## File : db_helper.rb ends
