# -*- encoding: utf-8 -*-
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : common_library.rb
## Author : DennyZhang.com <denny@dennyzhang.com>
## Description :
## --
## Created : <2016-05-10>
## Updated: Time-stamp: <2016-06-08 15:24:21>
##-------------------------------------------------------------------
################################################################################
require 'socket'
require 'serverspec'
require 'open3'

# Required by serverspec
set :backend, :exec

# TODO: don't hardcode download link
url_prefix = 'https://raw.githubusercontent.com/DennyZhang/devops_public/master/serverspec'

# TODO: conditional download to avoid network turbulence
%w(general_helper couchbase_helper elasticsearch_helper
   jenkins_helper).each do |library|
  download_command = "curl -o /opt/#{library}.rb #{url_prefix}/#{library}.rb"
  system(download_command)
  require_relative "/opt/#{library}"
end
#############################################################################
## File : common_library.rb ends
