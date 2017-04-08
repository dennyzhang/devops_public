#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
## https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : setup_jenkins.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
## --
## Created : <2016-04-20>
## Updated: Time-stamp: <2017-04-08 15:14:22>
##-------------------------------------------------------------------
function configure_jenkins_port() {
    port=${1?}
    if ! grep "HTTP_PORT=$port" /etc/default/jenkins 1>/dev/null 2>&1; then
        echo "Reset Jekins port to $port"
        sed -i "s/HTTP_PORT=.*/HTTP_PORT=$port/g" /etc/default/jenkins
        service jenkins restart
    fi
}

function install_jenkins() {
    if ! (dpkg -s jenkins | grep "Status: install" 1>/dev/null 2>&1); then
        # https://wiki.jenkins-ci.org/display/JENKINS/Installing+Jenkins+on+Ubuntu
        # Latest Jenkins2.0 deployment will fail in Ubuntu 14.04
        # echo "setup jenkins"
        # wget -q -O - https://jenkins-ci.org/debian/jenkins-ci.org.key | sudo apt-key add -
        # sh -c 'echo deb http://pkg.jenkins-ci.org/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
        # apt-get -y update
        # apt-get install -y jenkins

        if ! which java 1>/dev/null 2>&1; then
            echo "Install java"
            apt-get install -y java-common openjdk-7-jre-headless default-jre-headless
        fi

        apt-get install -y daemon psmisc
        # TODO: host the file
        if [ ! -f /tmp/jenkins_1.658_all.deb ]; then
            curl -o /tmp/jenkins_1.658_all.deb http://mirror.xmission.com/jenkins/debian/jenkins_1.658_all.deb
        fi
        dpkg -i /tmp/jenkins_1.658_all.deb
    fi
}

function setup_jenkins_jobs() {
    http_prefix="https://raw.githubusercontent.com/TOTVS/mdmpublic/tag_v5/chef/setup_jenkins/jenkins_jobs"
    jenkins_jobs="DeploySystem,RunCommandOnServers,MonitorServerFileChanges,VerifySystem,CollectFiles,CommonServerCheck"
    should_restart=false
    IFS=','
    for job_name in $jenkins_jobs; do
        unset IFS
        job_url="${http_prefix}/${job_name}/config.xml"
        # TODO: check whether to update
        mkdir -p "/var/lib/jenkins/jobs/$job_name"
        echo "Download config.xml for Jenkins job $job_name"
        curl -o "/var/lib/jenkins/jobs/$job_name/config.xml" "$job_url"
        should_restart=true
    done

    if $should_restart; then
        chown jenkins:jenkins -R /var/lib/jenkins/jobs
        echo "reload Jenkins jobs"
        service jenkins force-reload
    fi
}

function grant_jenkins_privilege() {
    if [ ! -f /etc/sudoers.d/jenkins ]; then
        echo '%jenkins ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/jenkins
    fi
}

function jenkins_ssh_file_setup() {
    if [ ! -f /var/lib/jenkins/.ssh/ci_id_rsa ]; then
        mkdir -p /var/lib/jenkins/.ssh
        chown jenkins:jenkins -R /var/lib/jenkins/.ssh
        touch /var/lib/jenkins/.ssh/ci_id_rsa
        chmod 400 /var/lib/jenkins/.ssh/ci_id_rsa
    fi
}

jenkins_port=18080

grant_jenkins_privilege
install_jenkins
configure_jenkins_port $jenkins_port
setup_jenkins_jobs
jenkins_ssh_file_setup

# TODO: use real ip
echo "Jenkins is up: http://\$server_ip:$jenkins_port"
echo "Action Done"
## File : setup_jenkins.sh ends
