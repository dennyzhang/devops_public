#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
## https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : setup_jenkins.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
## --
## Created : <2016-04-20>
## Updated: Time-stamp: <2016-05-25 17:20:36>
##-------------------------------------------------------------------
function install_jenkins() {
    if ! (dpkg -s jenkins | grep "Status: install" 1>/dev/null 2>&1); then
        echo "setup jenkins"
        wget -q -O - https://jenkins-ci.org/debian/jenkins-ci.org.key | apt-key add -
        sh -c 'echo deb http://pkg.jenkins-ci.org/debian binary/ > /etc/apt/sources.list.d/jenkins.list'
        apt-get update
        apt-get install -y jenkins
        # Grant privilege to jenkins user
        echo '%jenkins ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/jenkins
    fi
}

function setup_jenkins_jobs() {
    jenkins_jobs="DeploySystem,https://raw.githubusercontent.com/TOTVS/mdmpublic/master/chef/jenkins_jobs/deploysystem_config.xml"
    should_restart=false
    for job in $jenkins_jobs; do
        item=(${job//,/ })
        job_name=${item[0]}
        job_url=${item[1]}
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

install_jenkins

setup_jenkins_jobs

echo "Jenkins is up: http://\$server_ip:8080"
## File : setup_jenkins.sh ends
