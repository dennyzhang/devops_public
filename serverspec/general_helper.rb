# -*- encoding: utf-8 -*-

##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : general_helper.rb
## Author : DennyZhang.com <contact@dennyzhang.com>
## Description :
## --
## Created : <2016-05-10>
## Updated: Time-stamp: <2017-09-04 18:55:45>
##-------------------------------------------------------------------
################################################################################
require 'socket'
require 'serverspec'
require 'open3'

# Required by serverspec
set :backend, :exec

################################################################################
def local_ip
  # get current ip, probbably of eth0
  # turn off reverse DNS resolution temporarily
  orig = Socket.do_not_reverse_lookup
  Socket.do_not_reverse_lookup = true

  UDPSocket.open do |s|
    s.connect '8.8.8.8', 1
    s.addr.last
  end
ensure
  Socket.do_not_reverse_lookup = orig
end

def print_local_ip
  node_ip = local_ip
  print("==== local_ip: #{node_ip} ====")
end

def sleep_for(seconds)
  # After deployment, it might take a while for system to be up and running.
  # Hence we may need to sleep and test
  describe command("sleep #{seconds}") do
    its(:exit_status) { should eq 0 }
  end
end

def wait_for(seconds, condition)
  # Wait with timeout mechanism until given condition is satisfied
  describe command("bash /root/wait_for.sh '#{condition}' '#{seconds}'") do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should contain 'Action pass' }
  end
end

def list_get_random_item(list, skip_item = '')
  # When skip_item is empty, we get a random item from the list.
  # Otherwise, we get a random item from the list. It must not
  # be the one of skip_item.
  r = Random.new
  item = list[r.rand(list.length)]
  if skip_item != ''
    loop do
      break if item != skip_item
      item = list_get_random_item(list)
    end
  end
  item
end

def verify_process_cmdline_by_pidfile(pidfile, pattern)
  describe command("cat /proc/$(cat #{pidfile})/cmdline") do
    its(:stdout) { should contain pattern.to_s }
  end
end
#############################################################################
## File : general_helper.rb ends
