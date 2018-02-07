#!/usr/bin/env bash
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : perform_smoke_test.sh
## Author : DennyZhang.com <contact@dennyzhang.com>
## Description :
## --
## Created : <2015-08-16>
## Updated: Time-stamp: <2017-09-04 18:54:39>
##-------------------------------------------------------------------
################################################################################################
. /etc/profile
[ -n "$DOWNLOAD_TAG_NAME" ] || export DOWNLOAD_TAG_NAME="tag_v6"
export DOWNLOAD_PREFIX="https://raw.githubusercontent.com/DennyZhang/devops_public/${DOWNLOAD_TAG_NAME}"
if [ ! -f /var/lib/devops/refresh_common_library.sh ]; then
    [ -d /var/lib/devops/ ] || (sudo mkdir -p /var/lib/devops/ && sudo chmod 777 /var/lib/devops)
    wget -O /var/lib/devops/refresh_common_library.sh "$DOWNLOAD_PREFIX/common_library/refresh_common_library.sh"
    chmod 777 /var/lib/devops/refresh_common_library.sh
fi
bash /var/lib/devops/refresh_common_library.sh "3536991806" "/var/lib/devops/devops_common_library.sh" \
     "${DOWNLOAD_PREFIX}/common_library/devops_common_library.sh"
. /var/lib/devops/devops_common_library.sh
################################################################################################
function prepare_protractor() {
    working_dir=${1?}
    shift
    server_ip=${1?}
    shift
    gui_test_case=$*
    protractor_conf_cfg="$working_dir/protractor_conf.js"
    protractor_testcase="$working_dir/protractor_testcase.js"

    log "configure $protractor_conf_cfg"
    cat > "$protractor_conf_cfg" <<EOF
exports.config = {
    seleniumAddress: 'http://localhost:4444/wd/hub',
    // ----- What tests to run -----
    specs: ['$protractor_testcase'],
    // If you would like to run more than one instance of webdriver on the same
    // tests, use multiCapabilities, which takes an array of capabilities.
    // If this is specified, capabilities will be ignored.
    multiCapabilities: [
        {
            'browserName': 'chrome',
            'shardTestFiles': true,
            'maxInstances': 10,
            'acceptSslCerts': true,
            'trustAllSSLCertificates': true
        }
    ],
    // ----- Parameters for tests -----
    params: {
        login: {
            server_ip: '$server_ip',
        }
    },

    onPrepare: function() {
        browser.driver.manage().window().setSize(1600, 800);
    },

    jasmineNodeOpts: {
        showColors: true,
        defaultTimeoutInterval: 30000,
        isVerbose: true,
        includeStackTrace: true
    },
    // The timeout in milliseconds for each script run on the browser. This should
    // be longer than the maximum time your application needs to stabilize between
    // tasks.
    allScriptsTimeout: 30000,

    // How long to wait for a page to load.
    getPageTimeout: 30000
};
EOF

    log "configure $protractor_testcase"
    cat > "$protractor_testcase" <<EOF
describe('Authright GUI verification', function() {
url = "http://" + browser.params.login.server_ip

$gui_test_case

});
EOF
}

function test_protractor() {
    working_dir=${1?}
    protractor_conf_cfg="$working_dir/protractor_conf.js"
    log "================ protractor $protractor_conf_cfg ============"
    export LANG="en_US.UTF-8"
    export LC_ALL="en_US.UTF-8"
    protractor "$protractor_conf_cfg"
}

#################################################################################
working_dir="$HOME/code/smoketest/"
[ -d "$working_dir" ] || mkdir -p "$working_dir"

prepare_protractor "$working_dir" "$server_ip" "gui_test_case"
test_protractor "$working_dir"
## File : perform_smoke_test.sh ends
