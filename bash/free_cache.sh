#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
## https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : free_cache.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
## Sample:
## --
## Created : <2016-06-04>
## Updated: Time-stamp: <2016-06-16 11:22:36>
##-------------------------------------------------------------------
# http://unix.stackexchange.com/questions/17936/setting-proc-sys-vm-drop-caches-to-clear-cache
echo "Free cached memory, so that OS can have more free memory"

pre_memory=$(free -ml)
echo "$pre_memory" | cat

echo 3 | sudo tee /proc/sys/vm/drop_caches

pre_memory=$(free -ml)
echo "$pre_memory" | cat
## File: free_cache.sh ends
