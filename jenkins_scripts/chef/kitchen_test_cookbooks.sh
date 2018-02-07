#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : kitchen_test_cookbooks.sh
## Author : DennyZhang.com <contact@dennyzhang.com>
## Description :
## --
## Created : <2015-07-03>
## Updated: Time-stamp: <2017-09-04 18:54:40>
##-------------------------------------------------------------------
################################################################################################
## env variables:
##      git_repo_url: git@bitbucket.org:XXX/XXX.git
##      branch_name: dev
##      test_command: curl -L https://raw.githubusercontent.com/XXX/XXX/chef/kitchen_raw_test.sh | bash
##      cookbook_list: gateway-auth oauth2-auth account-auth audit-auth mfa-auth message-auth platformportal-auth ssoportal-auth tenantadmin-auth
##      skip_cookbook_list: sandbox-test
##      must_cookbook_list: gateway-auth
##      env_parameters:
##         export SKIP_CODE_UPDATE=false
##         export KEEP_FAILED_INSTANCE=true
##         export KEEP_INSTANCE=false
##         export REMOVE_BERKSFILE_LOCK=false
##         export CLEAN_START=false
##         export TEST_KITCHEN_YAML=
##               To test for *kitchen*.yml, set TEST_KITCHEN_YAML as ALL
##         export TEST_KITCHEN_YAML_BLACKLIST=".kitchen.vagrant.yml,.kitchen.digitalocean.yml"
##         export working_dir=$HOME/code/dockerfeature
################################################################################################
. /etc/profile
[ -n "$DOWNLOAD_TAG_NAME" ] || export DOWNLOAD_TAG_NAME="tag_v6"
export DOWNLOAD_PREFIX="https://raw.githubusercontent.com/DennyZhang/devops_public/${DOWNLOAD_TAG_NAME}"
if [ ! -f /var/lib/devops/refresh_common_library.sh ]; then
    [ -d /var/lib/devops/ ] || (mkdir -p /var/lib/devops/ && chmod 777 /var/lib/devops)
    wget -O /var/lib/devops/refresh_common_library.sh "$DOWNLOAD_PREFIX/common_library/refresh_common_library.sh"
    chmod 777 /var/lib/devops/refresh_common_library.sh
fi
bash /var/lib/devops/refresh_common_library.sh "3536991806" "/var/lib/devops/devops_common_library.sh" \
     "${DOWNLOAD_PREFIX}/common_library/devops_common_library.sh"
. /var/lib/devops/devops_common_library.sh
################################################################################################
function get_cookbooks() {
    cookbook_list=${1?}
    cookbook_dir=${2?}
    skip_cookbook_list=${3:-""}
    cd "$cookbook_dir"

    if [ "$cookbook_list" = "ALL" ]; then
        cookbooks=$(ls -1 .)
        cookbooks="$cookbooks"
    else
        cookbooks=${cookbook_list//,/ }
    fi

    # skip_cookbook_list
    cookbooks_ret=""
    for cookbook in $cookbooks; do
        if [[ "${skip_cookbook_list}" != *$cookbook* ]]; then
            cookbooks_ret="${cookbooks_ret}${cookbook} "
        fi
    done

    # must_cookbook_list
    if [ "$must_cookbook_list" = "ALL" ]; then
        must_cookbooks=$(ls -1 .)
        must_cookbooks="$must_cookbooks"
    else
        must_cookbooks=${must_cookbook_list//,/ }
    fi

    for cookbook in $must_cookbooks; do
        if [[ "${cookbooks_ret}" != *$cookbook* ]]; then
            cookbooks_ret="${cookbooks_ret}${cookbook} "
        fi
    done

    echo "$cookbooks_ret" | sed "s/ $//g"
}

function test_cookbook() {
    local test_command=${1?}
    local cookbook_dir=${2?}
    local cookbook=${3?}

    cd "${cookbook_dir}/${cookbook}"

    MY_BUILD_ID=$(echo "$BUILD_ID" | tr '_' '-')
    export CURRENT_COOKBOOK=$cookbook
    if [ -z "$INSTANCE_NAME" ]; then
        if [ -z "$BUILD_USER" ]; then
            export INSTANCE_NAME="${cookbook}-${JOB_NAME}-${MY_BUILD_ID}"
        else
            BUILD_USER=$(echo "$BUILD_USER" | sed 's/ /-/g')
            export INSTANCE_NAME="${cookbook}-${JOB_NAME}-${MY_BUILD_ID}-${BUILD_USER}"
        fi
    fi

    if [ "$TEST_KITCHEN_YAML" = "ALL" ]; then
        all_yml_list=$(ls .kitchen*\.yml)
        black_yml_list=${TEST_KITCHEN_YAML_BLACKLIST//,/\\n}
        yml_list=$(echo -e "${all_yml_list}\n${black_yml_list}\n${black_yml_list}" | sort | uniq -u )
        black_yml_list=($black_yml_list)
    else
        yml_list=(${TEST_KITCHEN_YAML//,/ })
    fi

    echo "yml list is:${yml_list[*]}"
    echo "======================== test cookbook: $cookbook"
    echo "======================== cd $(pwd)"
    echo "======================== export INSTANCE_NAME=$INSTANCE_NAME"
    # TODO: implement black_yml_list logic
    for yml in ${yml_list[*]}; do
        if [ -f "$yml" ]; then
            echo "======================== export KITCHEN_YAML=${yml}"
            echo "$test_command"
            export KITCHEN_YAML=${yml}
            if ! eval "$test_command"; then
                echo "ERROR $cookbook"
                failed_cookbooks="${failed_cookbooks} ${cookbook}:${yml}"
            fi
            echo "failed_cookbooks=$failed_cookbooks"
        else
            echo "Warning: $yml not found in $(pwd)"
        fi
    done
    unset INSTANCE_NAME
}

function test_cookbook_list() {
    test_command=${1?}
    cookbooks=${2?}
    cookbook_dir=${3?}

    for cookbook in $cookbooks; do
        test_cookbook "${test_command}" "${cookbook_dir}" "${cookbook}"
    done
}

function shell_exit() {
    errcode=$?
    exit $errcode
}
########################################################################
source_string "$env_parameters"
[ -n "$TEST_KITCHEN_YAML" ] || TEST_KITCHEN_YAML=".kitchen.yml"
[ -n "$working_dir" ] || working_dir="$HOME/code/$JOB_NAME"

git_repo=$(parse_git_repo "$git_repo_url")
code_dir="$working_dir/$branch_name/$git_repo"

if [ -n "$CLEAN_START" ] && $CLEAN_START; then
    [ ! -d "$code_dir" ] || rm -rf "$code_dir"
fi

if [ ! -d "$working_dir" ]; then
    mkdir -p "$working_dir"
    # chown -R jenkins:jenkins "$working_dir"
fi

if [ -d "$code_dir" ]; then
    if [ -n "$REMOVE_BERKSFILE_LOCK" ] && $REMOVE_BERKSFILE_LOCK; then
        cd "$code_dir/cookbooks"
        git checkout ./*/Berksfile.lock
    fi
fi

if [ -z "$SKIP_CODE_UPDATE" ] || [ "$SKIP_CODE_UPDATE" = "false" ]; then
    git_update_code "$branch_name" "$working_dir" "$git_repo_url"
fi

cookbook_dir="$code_dir/cookbooks"
cd "$cookbook_dir"

failed_cookbooks=""
cookbooks=$(get_cookbooks "$cookbook_list" "$cookbook_dir" "$skip_cookbook_list")

echo "Get cookbooks List"
echo "cookbooks: $cookbooks"

echo "Set locale as en_US.UTF-8"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

echo "Test Cookbooks"
test_cookbook_list "$test_command" "$cookbooks" "$cookbook_dir"

if [ "$failed_cookbooks" != "" ]; then
    echo "Failed cookbooks: $failed_cookbooks"
    exit 1
fi
## File : kitchen_test_cookbooks.sh ends
