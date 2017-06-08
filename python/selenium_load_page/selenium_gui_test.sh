#!/bin/bash -e
##-------------------------------------------------------------------
## File : selenium_gui_test.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
## --
## Created : <2017-05-18>
## Updated: Time-stamp: <2017-06-07 21:15:54>
##-------------------------------------------------------------------
url_test=${1?}
test_py_script=${2?"/home/seluser/scripts/selenium_load_page.py"}
maximum_seconds=${3:-"30"}
container_name=${4:-"selelinum"}
bind_hosts_list=${5:-""}

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

docker run -d -t -p 3128:443 denny/chefserver:v1 /usr/sbin/sshd -D
image_name="denny/selenium:v1"
py_script_in_container="/home/seluser/scripts/selenium_load_page.py"
docker run -t -d --privileged -h selenium \
       -v "$test_py_script:$py_script_in_container" \
       --name "$container_name" "$image_name"

if [ -n "$bind_hosts_list" ]; then
    echo "TODO: update hosts"
fi

# Run test
docker exec selenium python "$py_script_in_container" \
       --page_url "$url_test" --max_load_seconds "$maximum_seconds"
################################################################################
## File : selenium_gui_test.sh ends
