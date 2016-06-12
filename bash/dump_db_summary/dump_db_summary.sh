#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
## https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : dump_db_summary.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
## Sample:
## --
## Created : <2016-06-04>
## Updated: Time-stamp: <2016-06-12 09:56:06>
##-------------------------------------------------------------------
. /etc/profile

################################################################################
# Plugin Function
function dump_couchbase_summary() {
    local cfg_file=${1?}
    source "$cfg_file"
    echo "TODO"
}

function dump_elasticsearch_summary() {
    local cfg_file=${1?}
    source "$cfg_file"
    echo "TODO"
}

function dump_mongodb_summary() {
    local cfg_file=${1?}
    source "$cfg_file"
    echo "TODO"
}
################################################################################
cfg_dir=${1?}
# support string/json
output_type=${2:-"string"}

cd "$cfg_dir"
for f in *.cfg; do
    db_name=${f%%.cfg}
    fun_name="dump_${db_name}_summary"
    command="$fun_name $f"
    $command
done
## File: dump_db_summary.sh ends
