#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2017 DennyZhang.com
## Licensed under MIT
##   https://www.dennyzhang.com/wp-content/mit_license.txt
##
## File : refresh_containers.py
## Author : Denny <contact@dennyzhang.com>
## Description : Restart a list of docker containers.
##               If required, related docker images will be updated.
## Requirements:
##          pip install docker==2.0.0
## --
## Created : <2017-05-12>
## Updated: Time-stamp: <2017-09-07 21:36:07>
##-------------------------------------------------------------------
import sys
import docker

def pull_image_by_container(client, container_name):
    container = None
    try:
        container = client.containers.get(container_name)
    except docker.errors.NotFound as e:
        print("Error: No container is found with name of %s" % (container_name))
        sys.exit(1)

    docker_image = container.attrs['Config']['Image']
    print("docker pull %s" % (docker_image))
    client.images.pull(docker_image)
    
if __name__ == '__main__':
    client = docker.from_env()
    container_name = "my-test"
    pull_image_by_container(client, container_name)
## File : refresh_containers.py ends
