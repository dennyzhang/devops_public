#!/bin/bash -e
##-------------------------------------------------------------------
## File : digitalocean_cost_slack_report.sh
## Author : DennyZhang.com <denny@dennyzhang.com>
## Description :
## --
## Created : <2016-12-24>
## Updated: Time-stamp: <2016-12-24 19:57:10>
##-------------------------------------------------------------------

################################################################################################
## Purpose: Cost BreakDown For all Running DigitalOcean Droplets In Slack
##
## env variables:
##      env_parameters:
##          export DIGITALOCEAN_TOKEN="YOUR_DIGITALOCEAN_TOKEN"
##          export SLACK_TOKEN="YOUR_SLACK_TOKEN"
##          export SLACK_CHANNEL="YOUR_SLACK_CHANNEL"
################################################################################################
. /etc/profile
[ -n "$DOWNLOAD_TAG_NAME" ] || export DOWNLOAD_TAG_NAME="tag_v2"
export DOWNLOAD_PREFIX="https://raw.githubusercontent.com/DennyZhang/devops_public/${DOWNLOAD_TAG_NAME}"
if [ ! -f /var/lib/devops/refresh_common_library.sh ]; then
    [ -d /var/lib/devops/ ] || (sudo mkdir -p  /var/lib/devops/ && sudo chmod 777 /var/lib/devops)
    wget -O /var/lib/devops/refresh_common_library.sh "$DOWNLOAD_PREFIX/common_library/refresh_common_library.sh"
fi
bash /var/lib/devops/refresh_common_library.sh "1431551582" "/var/lib/devops/devops_common_library.sh" \
     "${DOWNLOAD_PREFIX}/common_library/devops_common_library.sh"
. /var/lib/devops/devops_common_library.sh
################################################################################################
function shell_exit() {
    errcode=$?
    rm -rf $tmp_fname
    exit $errcode
}

trap shell_exit SIGHUP SIGINT SIGTERM 0

source_string "$env_parameters"
[ -n "$MAX_DROPLETS_COUNT" ] || MAX_DROPLETS_COUNT=500
ensure_variable_isset "Error: DIGITALOCEAN_TOKEN can't be empty" "$DIGITALOCEAN_TOKEN"
ensure_variable_isset "Error: SLACK_TOKEN can't be empty" "$SLACK_TOKEN"
ensure_variable_isset "Error: SLACK_CHANNEL can't be empty" "$SLACK_CHANNEL"

tmp_fname="/tmp/Digitalocean_Cost_For_All_Droplets.txt"

which column 1>/dev/null || apt-get install -y bsdmainutils 1>/dev/null

echo "List All Droplets Of DigitalOcean"
curl -sXGET "https://api.digitalocean.com/v2/droplets?page=1&per_page=$MAX_DROPLETS_COUNT" \
       -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
       -H "Content-Type: application/json" |\
       python -c 'import sys,json;data=json.loads(sys.stdin.read());\
                  print "ID\tName\tIP\tPrice\n";\
                  print "\n".join(["%s\t%s\t%s\t$%s"%(d["id"],d["name"],d["networks"]["v4"][0]["ip_address"],d["size"]["price_monthly"])\
                  for d in data["droplets"]])'| column -t > $tmp_fname

echo "Send Slack messages"
curl -F file=@$tmp_fname -F initial_comment="Cost Breakdown For All Running Droplets" -F channels=#$SLACK_CHANNEL -F token=$SLACK_TOKEN https://slack.com/api/files.upload
## File : digitalocean_cost_slack_report.sh ends
