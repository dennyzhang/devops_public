#!/bin/bash -ex
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : refresh_db_report.sh
## Author : DennyZhang.com <denny@dennyzhang.com>
## Description :
## --
## Created : <2015-09-24>
## Updated: Time-stamp: <2016-07-28 09:56:36>
##-------------------------------------------------------------------
################################################################################################
## env variables:
##       env_parameters:
##           export SSH_DOCKER_DAEMON="ssh root@172.17.0.1"
################################################################################################
. /etc/profile
[ -n "$DOWNLOAD_TAG_NAME" ] || export DOWNLOAD_TAG_NAME="tag_v2"
export DOWNLOAD_PREFIX="https://raw.githubusercontent.com/DennyZhang/devops_public/${DOWNLOAD_TAG_NAME}"
if [ ! -f /var/lib/devops/refresh_common_library.sh ]; then
    [ -d /var/lib/devops/ ] || (sudo mkdir -p  /var/lib/devops/ && sudo chmod 777 /var/lib/devops)
    wget -O /var/lib/devops/refresh_common_library.sh "$DOWNLOAD_PREFIX/common_library/refresh_common_library.sh"
fi
bash /var/lib/devops/refresh_common_library.sh "2593132520" "/var/lib/devops/devops_common_library.sh" \
     "${DOWNLOAD_PREFIX}/common_library/devops_common_library.sh"
. /var/lib/devops/devops_common_library.sh
################################################################################################
export SSH_DOCKER_DAEMON="ssh root@172.17.0.1"

echo "destroy old docker container of data-report"
$SSH_DOCKER_DAEMON docker stop data-report || true
$SSH_DOCKER_DAEMON docker rm data-report || true

echo "start elk data report container and services inside"
$SSH_DOCKER_DAEMON docker run -t -d --name data-report --privileged -p 5601:5601 denny/elk:datareport /usr/sbin/sshd -D

$SSH_DOCKER_DAEMON docker exec -t data-report service logstash start
$SSH_DOCKER_DAEMON docker exec -t data-report service elasticsearch start
$SSH_DOCKER_DAEMON docker exec -t data-report service kibana4 start

echo "Download and inject data file"
$SSH_DOCKER_DAEMON docker exec -t data-report wget -O /tmp/db_summary_report.txt http://repo.fluigdata.com:18000/prodenv_db_summary_report/db_summary_report.txt
$SSH_DOCKER_DAEMON docker exec -t data-report cat /tmp/db_summary_report.txt >> /var/log/data_report.log

# http://104.131.129.100:5601
# TODO: whether to shutdown container
## File : refresh_db_report.sh ends
