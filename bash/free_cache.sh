#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
## https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : free_cache.sh
## Author : Denny <contact@dennyzhang.com>
## Description :
## Sample:
## --
## Created : <2016-06-04>
## Updated: Time-stamp: <2017-09-04 18:54:43>
##-------------------------------------------------------------------
# http://unix.stackexchange.com/questions/17936/setting-proc-sys-vm-drop-caches-to-clear-cache
echo "Free cached memory, so that OS can have more free memory"

pre_memory=$(free -ml)
echo "$pre_memory" | cat

echo 3 | sudo tee /proc/sys/vm/drop_caches

pre_memory=$(free -ml)
echo "$pre_memory" | cat
## File: free_cache.sh ends
