#!/bin/bash -x
set +e

# get list of nodes
hosts_list=""
for node in $(kitchen list | grep -v '^Instance' | awk -F' ' '{print $1}'); do
    output=$(kitchen exec "$node" -c "sudo /sbin/ifconfig eth0 | grep 'inet addr:'")
    ip=$(echo "$output" | grep -v LC_ALL | grep -v '^---' | cut -d: -f2 | awk '{print $1}')
    output=$(kitchen exec "$node" -c "sudo hostname")
    hostname=$(echo "$output" | grep -v LC_ALL | grep -v '^---')
    # trim whitespace
    hostname=$(echo "${hostname}" | sed -e 's/^[ \t]*//')
    # TODO: verify ip and hostname are valid
    hosts_list="${hosts_list},${ip}:${hostname}"
done
echo "hosts_list: $hosts_list"

hosts_arr=(${hosts_list//,/ })
# update /etc/hosts
for host in ${hosts_arr[*]}
do
    host_split=(${host//:/ })
    ip=${host_split[0]}
    domain=${host_split[1]}

    for node in $(kitchen list | grep -v '^Instance' | awk -F' ' '{print $1}'); do
        kitchen exec "$node" -c "sudo cp -f /etc/hosts /root/hosts"
        if kitchen exec "$node" -c "sudo grep ${domain} /root/hosts"; then
            command="sed -i \"/${domain}/c\\${ip}    ${domain}\" /root/hosts"
        else
            command="echo \"${ip}    ${domain}\" >> /root/hosts"
        fi
        kitchen exec "$node" -c "sudo $command"
        kitchen exec "$node" -c "sudo cp -f /root/hosts /etc/hosts"
    done
done
