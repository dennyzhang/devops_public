#!/bin/bash -e
##-------------------------------------------------------------------
## File : selenium_gui_test.sh
## Author : Denny <contact@dennyzhang.com>
## Description :
## --
## Created : <2017-05-18>
## Updated: Time-stamp: <2017-09-04 18:54:35>
##-------------------------------------------------------------------
url_test=${1?}
test_py_script=${2?"/home/seluser/scripts/selenium_load_page.py"}
maximum_seconds=${3:-"30"}
container_name=${4:-"selenium"}
add_host=${5:-""}

image_name="denny/selenium:v1"
py_script_in_container="/home/seluser/scripts/selenium_load_page.py"
working_dir="/root/selenium_test"

[ -d "$working_dir" ] || mkdir -p "$working_dir"

function destroy_container() {
    container_name=${1?}
    # TODO: better implementation
    if docker ps -a | grep "$container_name"; then
        docker stop "$container_name"; docker rm "$container_name"
    fi
}

function shell_exit() {
    errcode=$?
    destroy_container "$container_name"
    exit $errcode
}

trap shell_exit SIGHUP SIGINT SIGTERM 0

# Start docker container
destroy_container "$container_name"

if [ -z "$add_host" ]; then
    docker run -t -d --privileged -h selenium \
           -v "$test_py_script:$py_script_in_container" \
           --name "$container_name" "$image_name"
else
    docker run -t -d --privileged -h selenium \
           --add-host="$add_host" \
           -v "$test_py_script:$py_script_in_container" \
           --name "$container_name" "$image_name"
fi

# TODO: better way
sleep 5

# Run test
docker exec "$container_name" python "$py_script_in_container" \
       --page_url "$url_test" --max_load_seconds "$maximum_seconds"
################################################################################
## File : selenium_gui_test.sh ends
