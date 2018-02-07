#!/bin/bash -e
##--------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File: iam_install.sh
## Author: UU <youyou.li78@gmail.com>
## Description:
## --
## Created: <2016-01-06>
## Updated: Time-stamp: <2017-09-04 18:54:37>
##--------------------------------------------------------
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
function start_docker_daemon() {
    if ! service docker status | grep running;then
        log "start docker:"
        service docker start
    fi
}

function load_docker_image() {
    docker_tar=${1}
    log "docker load image:$docker_tar"
    docker load -i "./$docker_tar"
}
################################################################################################
case "$1" in
    load-image)
        fail_unless_root
        start_docker_daemon
        docker_tar=${2:-"denny_osc_latest.tar.bz2"}
        load_docker_image "$docker_tar"
        ;;

    start-docker-jenkins)
        fail_unless_root
        start_docker_daemon

        container_name="docker-jenkins"
        image_name="denny/osc:latest"
        log "start to create container docker-jenkins ..."
        container_status=$(is_container_running "${container_name}")

        if [ "$container_status" = "none" ];then
            docker run -d -t -h dockerjenkins --privileged \
                   --name ${container_name} -p 4022:22 -p 28000:28000 -p 28080:28080 -p 3128:3128 \
                   $image_name /usr/sbin/sshd -D
        elif [ "$container_status" = "dead" ];then
            docker start ${container_name}
        fi

        docker exec -it ${container_name} bash -c "service jenkins start"
        docker exec -it ${container_name} bash -c "service apache2 start"
        log "ok"
        ;;

    start-docker-all-in-one)
        fail_unless_root
        start_docker_daemon

        container_name="docker-all-in-one"
        image_name="denny/osc:latest"
        log "start to create container ${container_name} ..."
        container_status=$(is_container_running "docker-all-in-one")

        if [ "$container_status" = "none" ];then
            docker run -d -t --privileged -h dockeraio --name "${container_name}" \
                   -p 10000-10050:10000-10050 -p 80:80 -p 443:443 \
                   -p 6022:22 -p 1389:1389 $image_name /usr/sbin/sshd -D
        elif [ "$container_status" = "dead" ];then
            docker start ${container_name}
        fi
        log "ok"
        ;;

    inject-keys)
        fail_unless_root

        log "connect VM and container:"
        [ -d /root/.ssh ] || mkdir -p /root/.ssh && touch /root/.ssh/authorized_keys
        grep contact@dennyzhang.com /root/.ssh/authorized_keys || echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGVkT4Ka/Pt6M/xREwYWatYyBqaBgDVS1bCy7CViZ5VGr1z+sNwI2cBoRwWxqHwvOgfAm+Wbzwqs+WNvXW6GDZ1kjayh2YnBN5UBYZjpNQK9tmO8KHQwX29UvOaOJ6HIEWOJB9ylyUoWL+WwNf71arpXULBW6skx9fp9F5rHuB0UmQ+omhJGs6+PRSLAEzWaQvtxmm7CuZ7LgslNKskkqx/6CHlQPq2qchRVN5xvnZPuFWgF6cvWvK7kylAQsv8hQtFGsE9Rw1itjisCBVILzEC2mAjg5SqeEB0i7QwdlRr4jgxaxO5jR9wdKo7PaEl9+bibuZrCIhp6V4Y4eaIzAP contact@dennyzhang.com" >> /root/.ssh/authorized_keys
        log "ok"
        ;;

    bootstrap-up)
        fail_unless_root

        log "cp docker_sandbox.sh to /etc/init.d/docker_sandbox"
        rm -rf /etc/init.d/docker_sandbox
        update-rc.d docker_sandbox remove

        cp docker_sandbox.sh /etc/init.d/docker_sandbox
        chmod 755 /etc/init.d/docker_sandbox
        update-rc.d docker_sandbox defaults
        update-rc.d docker_sandbox enable
        log "ok"
        ;;

    all)
        $0 load-image
        $0 start-docker-jenkins
        $0 start-docker-all-in-one
        $0 inject-keys
        $0 bootstrap-up
        ;;

    clean)
        fail_unless_root
        start_docker_daemon

        log "stop container:"
        docker ps -a --format "{{.Names}}" | xargs docker stop

        log "remove container:"
        docker ps -a --format "{{.Names}}" | xargs docker rm
        log "ok"
        ;;
    *)
        echo "Usage: $0 {all/load-image/start-docker-jenkins/start-docker-all-in-one/inject-keys/bootstrap-up/clean}"
        exit 1
        ;;
esac
## File : iam_install.sh ends
