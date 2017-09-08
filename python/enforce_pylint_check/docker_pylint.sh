#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2017 DennyZhang.com
## Licensed under MIT 
##   https://www.dennyzhang.com/wp-content/mit_license.txt
##
## File : docker_pylint.sh
## Author : Denny <contact@dennyzhang.com>
## Description :
## --
## Created : <2017-05-12>
## Updated: Time-stamp: <2017-09-07 21:35:49>
##-------------------------------------------------------------------
code_dir=${1?""}
preinstall_pip_packages=${2-""}
ignore_file_list=${3-""}

image_name="denny/pylintcheck:1.0"
check_filename="/enforce_pylint.py"

current_filename=$(basename "$0")
test_id="${current_filename%.sh}_$$"
container_name="$test_id"
ignore_file="$test_id"

function remove_container() {
    container_name=${1?}
    if docker ps -a | grep "$container_name" 1>/dev/null 2>&1; then
        echo "Destroy container: $container_name"
        docker stop "$container_name"; docker rm "$container_name"
    fi
}

function shell_exit() {
    errcode=$?
    if [ $errcode -eq 0 ]; then
        echo "Test has passed."
    else
        echo "ERROR: Test has failed."
    fi

    echo "Remove tmp file: $ignore_file"
    rm -rf "/tmp/$ignore_file"

    remove_container "$container_name"
    exit $errcode
}

################################################################################
trap shell_exit SIGHUP SIGINT SIGTERM 0

echo "Generate the ignore file for code check"
echo "$ignore_file_list" > "/tmp/$ignore_file"

echo "Start container"
remove_container "$container_name"
docker run -t -d --privileged -v "${code_dir}:/code" --name "$container_name" --entrypoint=/bin/sh "$image_name"

echo "Copy ignore file"
docker cp "/tmp/$ignore_file" "$container_name:/$ignore_file"

echo "Install pip packages before testing"
package_list=${preinstall_pip_packages//,/ }
for pip_package in $package_list; do
    echo "pip install $pip_package"
    docker exec -t "$container_name" pip install "$pip_package"
done

echo "Run code check: python $check_filename --code_dir /code --check_ignore_file /${ignore_file}"
docker exec -t "$container_name" python "$check_filename" --code_dir /code --check_ignore_file "/${ignore_file}"
## File : docker_pylint.sh ends
