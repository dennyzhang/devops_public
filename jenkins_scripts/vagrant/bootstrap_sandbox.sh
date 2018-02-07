#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : bootstrap_sandbox.sh
## Author : DennyZhang.com <contact@dennyzhang.com>
## Description :
## --
## Created : <2015-05-28>
## Updated: Time-stamp: <2017-09-04 18:54:37>
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
image_name=${1?"docker image name"}
use_private_hub=${2:-"no"}
image_repo_name=${image_name%:*}
################################################################################################
function docker_pull_image() {
    local image_repo_name=${1?}
    local image_name=${2?}
    local flag_file=${3?}

    old_image_id=""
    if docker images | grep "$image_repo_name"; then
        old_image_id=$(docker images | grep "$image_repo_name" | awk -F' ' '{print $3}')
    fi

    log "docker pull $image_name, this steps may take tens of minutes."
    set +e
    docker pull "$image_name"
    errcode=$?
    if [ $errcode -eq 0 ]; then
        log "Retry: docker pull $image_name, in case doggy internet issue."
        docker pull "$image_name"
    fi
    set -e

    new_image_id=$(docker images | grep "$image_repo_name" | awk -F' ' '{print $3}')

    if [ "$old_image_id" = "$new_image_id" ]; then
        echo "no" > "$flag_file"
    else
        echo "yes" > "$flag_file"
    fi
}

function enable_private_docker_hub() {
    # change /etc/hosts
    log "enable private docker hub"
    if ! grep 'www.testdocker.com' /etc/hosts 2>/dev/null 1>/dev/null; then
        log "append /etc/hosts for '123.57.240.189 www.testdocker.com'"
        echo "123.57.240.189 www.testdocker.com" >> /etc/hosts
    fi

    if [ ! -f /usr/local/share/ca-certificates/docker-dev-cert ]; then
        log "Install docker hub ssl key: /usr/local/share/ca-certificates/docker-dev-cert"
        mkdir -p /usr/local/share/ca-certificates/
        cat > /usr/local/share/ca-certificates/docker-dev-cert/devdockerCA.crt <<EOF
-----BEGIN CERTIFICATE-----
MIIDXTCCAkWgAwIBAgIJAPvIhXM0kD6kMA0GCSqGSIb3DQEBCwUAMEUxCzAJBgNV
BAYTAkFVMRMwEQYDVQQIDApTb21lLVN0YXRlMSEwHwYDVQQKDBhJbnRlcm5ldCBX
aWRnaXRzIFB0eSBMdGQwHhcNMTUwNzE4MDU1MjQ1WhcNNDIxMjAzMDU1MjQ1WjBF
MQswCQYDVQQGEwJBVTETMBEGA1UECAwKU29tZS1TdGF0ZTEhMB8GA1UECgwYSW50
ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB
CgKCAQEAsf1Owc4D073Qlq3f9fp6PKlclXBC0HdLFx0F+6cICCj1/UMGlMECXvAr
+mWQaRfIHTxOumurmgV3wigX1VaoWiXYfYyD1jfTPHAP1fLA6wol9VB2+rR/i03x
z6AoNPNZARUoxeShfDho7SsSjm1b7Hu7y2um6Ed1JEn7THJrpB4dBd38VUg2vQwN
nsIhvE+ubzZelZUn9vrMTavlPkeCJu0xJuhCbSD6WdB0gL1I79XF42bGk2cSUrNO
o4AHwQzmA9bFbpLCQXqTJdkZv4/SyOlljUXTkqR2JBIuv7G+SaTgkrChX9neBy4n
aQ5sZZXqE1CVqDlX0BAXbGqbWWhW/QIDAQABo1AwTjAdBgNVHQ4EFgQUB8fUo0mM
4qJKs8pmDdPwlxubvQEwHwYDVR0jBBgwFoAUB8fUo0mM4qJKs8pmDdPwlxubvQEw
DAYDVR0TBAUwAwEB/zANBgkqhkiG9w0BAQsFAAOCAQEAbFMxM02/bCXUqrvwWNWr
Nv5DtPLXiwAEOA2sm7PNRnPemWLrhxpmmAGMfanL9Hj776zj+XMV0nCE3WAG5HTV
j1VdRMfshPmGmo+Jyl4pmQdUdm3FTAQcaTSP0lVSVQUYQ6xogBxVBQMEn/zm0UeL
BHvUltkhgmZN1Iz996pwztOngBBffCGX0ylvUWczySgjULzY/I2Lf2Cu4iQinnLy
8MWXWEzbYKy5zLG9hXO3yorIzrPLFy0jVccqY12SKhKdzlFT8O1b67x9ZFteMHuy
383mAn6tSSq7/u3OvtX7NTxaGAw1HVpWkEc8pp5SZtA3Vi6ihf04/145YY1FNk/M
OA==
-----END CERTIFICATE-----
EOF
        sudo update-ca-certificates

        docker login -u mydocker -p dockerpasswd -e ' ' https://www.testdocker.com:8080
    fi
}

function shell_exit() {
    exit_code=$?
    END=$(date +%s)
    DIFF=$(echo "$END - $START" | bc)
    log "Track time spent: $DIFF seconds"
    if [ $exit_code -eq 0 ]; then
        log "All set. Let's try Jenkins now: http://\$server_ip:28080"
    else
        log "ERROR: the procedure failed"
    fi
    exit $exit_code
}

function config_auto_start() {
    local service_name=${1?}
    local os_release_name
    os_release_name=$(os_release)
    if [ "$os_release_name" == "ubuntu" ]; then
        update-rc.d "$service_name" defaults
        update-rc.d "$service_name" enable
    fi

    if [ "$os_release_name" == "redhat" ] || [ "$os_release_name" == "centos" ]; then
        chkconfig "$service_name" on
    fi
}

################################################################################################
START=$(date +%s)
fail_unless_root

update_system

trap shell_exit SIGHUP SIGINT SIGTERM 0

# set PATH, just in case binary like chmod can't be found
PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

if [ "$use_private_hub" = "yes" ]; then
    enable_private_docker_hub
fi

log "Install docker"
install_docker

create_enough_loop_device

if ! service docker status 1>/dev/null 2>&1; then
    service docker start
fi

log "prepare shared directory for docker"
mkdir -p /root/docker/

log "Install autostart script for /etc/init.d/docker_sandbox"
curl -o /etc/init.d/docker_sandbox "${DOWNLOAD_PREFIX}/bash/docker_facility/docker_sandbox.sh"
chmod 755 /etc/init.d/docker_sandbox
config_auto_start "docker_sandbox"

log "Start docker of docker-jenkins"
flag_file="image.txt"

docker_pull_image "$image_repo_name" "$image_name" "$flag_file"
image_has_new_version=$(cat $flag_file)

container_name="docker-jenkins"
hostname="jenkins"
container_status=$(is_container_running $container_name)
if [ "$container_status" = "running" ] && [ "$image_has_new_version" = "yes" ]; then
    log "$image_name has new version, stop old running container: $container_name"
    docker stop $container_name
    docker rm $container_name
    container_status="none"
fi

if [ $container_status = "none" ]; then
    docker run -d -t --privileged -v "/root/docker/:$HOME/code/" \
            -h "$hostname" --name "$container_name" -p 4022:22 -p 28000:28000 \
            -p 28080:28080 -p 3128:3128 \
            "$image_name" /usr/sbin/sshd -D
elif [ $container_status = "dead" ]; then
    docker start $container_name
fi

log "Start docker of docker-all-in-one"
container_name="docker-all-in-one"
hostname="aio"
container_status=$(is_container_running $container_name)
if [ "$container_status" = "running" ] && [ "$image_has_new_version" = "yes" ]; then
    log "$image_name has new version, stop old running container: $container_name"
    docker stop $container_name
    docker rm $container_name
    container_status="none"
fi

if [ $container_status = "none" ]; then
    docker run -d -t --privileged --name $container_name -h $hostname \
           -p 10000-10050:10000-10050 -p 80:80 \
           -p 1389:1389 -p 443:443 \
           -p 6022:22 "$image_name" /usr/sbin/sshd -D
elif [ $container_status = "dead" ]; then
    docker start $container_name
fi

log "Start services inside docker"
service docker_sandbox start

for d in /root/docker/*; do
    [ ! -d "$d" ] || continue
    rm -rf "${d:?}"/*
done

chmod 777 -R /root/docker/

log "Check docker containers: docker ps"
docker ps
## File : bootstrap_sandbox.sh ends
