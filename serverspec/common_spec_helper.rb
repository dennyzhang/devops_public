# -*- encoding: utf-8 -*-
#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : common_spec_helper.rb
## Author : DennyZhang.com <denny@dennyzhang.com>
## Description :
## --
## Created : <2016-05-10>
## Updated: Time-stamp: <2016-05-24 06:45:33>
##-------------------------------------------------------------------
################################################################################################
require 'socket'
require 'serverspec'
require 'open3'

# Required by serverspec
set :backend, :exec
#############################################################################
# General functions
def local_ip
  # get current ip, probbably of eth0
  # turn off reverse DNS resolution temporarily
  orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true

  UDPSocket.open do |s|
    s.connect '8.8.8.8', 1
    s.addr.last
  end
ensure
  Socket.do_not_reverse_lookup = orig
end

def sleep_for(seconds)
  # After deployment, it might take a while for system to be up and running.
  # Hence we may need to sleep and test
  describe command("sleep #{seconds}") do
    its(:exit_status) { should eq 0 }
  end
end

def list_get_random_item(list, skip_item = '')
  # When skip_item is empty, we get a random item from the list.
  # Otherwise, we get a random item from the list. It must not be the one of skip_item.
  r = Random.new
  item = list[r.rand(list.length)]
  if skip_item != ''
    loop do
      if item == skip_item
        item = list_get_random_item(list)
      else
        break
      end
    end
  end
  item
end

#############################################################################
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
                  "#{server_ip}:#{tcp_port}/pools/default | grep -o 'otpNode' | wc -l"

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
# elasticsearch
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
# Jenkins
def wait_jenkins_up(jenkins_run_cmd)
  # After Jenkins deployment, it may take a while for Jenkins to be up and running
  # TODO: make code more general
  url_link_prefix = \
  'https://raw.githubusercontent.com/TOTVS/mdmpublic/master/common_bash/jenkins'

  %w(poll_jenkins_job.sh wait_jenkins_up.sh).each do |f|
    describe command(jenkins_run_cmd + " curl -o /root/#{f} #{url_link_prefix}/#{f}") do
      its(:exit_status) { should eq 0 }
    end
  end

  # Wait for jenkins to up
  describe command(jenkins_run_cmd + ' bash /root/wait_jenkins_up.sh ' \
                                     'http://127.0.0.1:18080/jnlpJars/jenkins-cli.jar') do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should contain 'Jenkins is up' }
  end

  # Download facility tools from Jenkins
  describe command(jenkins_run_cmd + ' curl -o /root/jenkins-cli.jar ' \
                                     'http://127.0.0.1:18080/jnlpJars/jenkins-cli.jar') do
    its(:exit_status) { should eq 0 }
  end
end

# functions to trigger jenknis jobs
def run_jenkins_job(jenkins_run_cmd, job_name, parameters)
  # Run Jenkins jobs by jenkins CLI
  describe command("#{jenkins_run_cmd} #{job_name} -w #{parameters}") do
    its(:stdout) { should contain 'Started ' }
    its(:exit_status) { should eq 0 }
  end
end

def run_jenkins_job_with_retry(jenkins_run_cmd, jenkins_check_cmd, job_name, parameters)
  # Run Jenkins jobs. If it fails for the first time, give a retry
  run_command = "#{jenkins_run_cmd} #{job_name} -w #{parameters}"
  describe command(run_command) do
    its(:stdout) { should contain 'Started ' }
    its(:exit_status) { should eq 0 }
  end

  describe command("#{jenkins_check_cmd} #{job_name}|| #{run_command}") do
    its(:exit_status) { should eq 0 }
  end

  describe command("#{jenkins_check_cmd} #{job_name}") do
    its(:stdout) { should contain 'Jenkins job success: ' }
    its(:exit_status) { should eq 0 }
  end
end

def run_check_jenkins_job(jenkins_run_cmd, jenkins_check_cmd, job_name, parameters)
  # Run jenkins jobs once and verify the job status
  describe command("#{jenkins_run_cmd} #{job_name} -w #{parameters}") do
    its(:stdout) { should contain 'Started ' }
    its(:exit_status) { should eq 0 }
  end

  describe command("#{jenkins_check_cmd} #{job_name}") do
    its(:stdout) { should contain 'Jenkins job success: ' }
    its(:exit_status) { should eq 0 }
  end
end
#############################################################################
## File : common_spec_helper.rb ends