#!/bin/bash -x
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : preinstall_kitchen_verify.sh
## Author : Denny <contact@dennyzhang.com>
## Description :
## --
## Created : <2015-11-30>
## Updated: Time-stamp: <2017-09-04 18:54:42>
##-------------------------------------------------------------------
LOG_FILE="/var/log/preinstall_kitchen_verify.log"
function log() {
    local msg=$*
    date_timestamp=$(date +['%Y-%m-%d %H:%M:%S'])
    echo -ne "$date_timestamp $msg\n"

    if [ -n "$LOG_FILE" ]; then
        echo -ne "$date_timestamp $msg\n" >> "$LOG_FILE"
    fi
}

# tolerant for failure
set +e

export BUSSER_ROOT="/tmp/verifier"
export BUSSER_ROOT GEM_HOME="/tmp/verifier/gems";
export GEM_HOME GEM_PATH="/tmp/verifier/gems";
export GEM_PATH GEM_CACHE="/tmp/verifier/gems/cache";
# export GEM_CACHE ruby="/opt/chefdk/embedded/bin/ruby"
# export gem="/opt/chefdk/embedded/bin/gem"
export GEM_CACHE ruby="/opt/chef/embedded/bin/ruby"
export gem="/opt/chef/embedded/bin/gem"
export version="busser"
export gem_install_args="busser --no-rdoc --no-ri"
export busser="sudo -E /tmp/verifier/bin/busser"
export plugins="busser-serverspec"

$gem list busser -i 1>/dev/null 2>&1

if test $? -ne 0; then
    log "-----> Installing Busser ($version)"
    $gem install "$gem_install_args"
else
    log "-----> Busser installation detected ($version)"
fi

log "gem install serverspec"
$gem install serverspec --no-rdoc --no-ri

if test ! -f "$BUSSER_ROOT/bin/busser"; then
    gem_bindir=$($ruby -rrubygems -e "puts Gem.bindir")
    log "$gem_bindir/busser setup"
    "${gem_bindir}/busser" setup
fi

log "Installing Busser plugins: $plugins"
$busser plugin install $plugins

log "Running cleanup"
$busser suite cleanup

log "Running test"
$busser test

# rm -rf $BUSSER_ROOT/bin/busser

chmod 777 -R /tmp/verifier
## File : preinstall_kitchen_verify.sh ends
