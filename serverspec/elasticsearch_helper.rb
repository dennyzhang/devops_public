# -*- encoding: utf-8 -*-
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : elasticsearch_helper.rb
## Author : DennyZhang.com <denny@dennyzhang.com>
## Description :
## --
## Created : <2016-05-10>
## Updated: Time-stamp: <2016-06-05 11:30:50>
##-------------------------------------------------------------------
require 'socket'
require 'serverspec'
require 'open3'

# Required by serverspec
set :backend, :exec

################################################################################
def elasticsearch_general_check(es_port)
  # Basic verification logic for elasticsearch installation
  describe command('/usr/share/elasticsearch/bin/elasticsearch --version') do
    its(:stdout) { should contain 'Version: 2.1.1' }
  end

  describe service('elasticsearch') do
    it { should be_running }
  end

  describe port(es_port) do
    it { should be_listening }
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
    its(:stdout) { should contain "\"status\" : \"green\"" }
  end
end
#############################################################################
## File : elasticsearch_helper.rb ends
