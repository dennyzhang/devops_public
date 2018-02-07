#!/bin/bash -e
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
### BEGIN INIT INFO
# Provides: docker_sandbox
# Required-Start:
# Required-Stop:
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description:
# Description:
### END INIT INFO
################################################################################################
. /etc/profile
[ -n "$DOWNLOAD_TAG_NAME" ] || export DOWNLOAD_TAG_NAME="tag_v6"
export DOWNLOAD_PREFIX="https://raw.githubusercontent.com/DennyZhang/devops_public/${DOWNLOAD_TAG_NAME}"
if [ ! -f /var/lib/devops/refresh_common_library.sh ]; then
    [ -d /var/lib/devops/ ] || (sudo mkdir -p  /var/lib/devops/ && sudo chmod 777 /var/lib/devops)
    wget -O /var/lib/devops/refresh_common_library.sh "$DOWNLOAD_PREFIX/common_library/refresh_common_library.sh"
    chmod 777 /var/lib/devops/refresh_common_library.sh
fi
bash /var/lib/devops/refresh_common_library.sh "3536991806" "/var/lib/devops/devops_common_library.sh" \
     "${DOWNLOAD_PREFIX}/common_library/devops_common_library.sh"
. /var/lib/devops/devops_common_library.sh
################################################################################################
case "$1" in
    start)
        log "run docker_sandbox.sh"
        if ! service docker status | grep running;then
            # start docker
            log "start docker:"
            service docker start
        fi

        log "start docker container docker-jenkins and docker-all-in-one"
        docker start docker-jenkins
        docker start docker-all-in-one

        log "sleep a while for containers to be up and running"
        sleep 5

        log "start services inside the docker-jenkins"
        docker exec docker-jenkins service jenkins start
        docker exec docker-jenkins service apache2 start

        log "start services inside the docker-all-in-one"

        log "Finish run docker_sandbox.sh"
        ;;
    *)
        echo "Usage: $0 {start}" >&2
        exit 1
        ;;
esac
## File : docker_sandbox.sh ends
