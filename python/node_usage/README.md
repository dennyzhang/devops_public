Check more: http://www.dennyzhang.com/chatqueryhost

# Install the agent of node status

```
apt-get install -y python-dev python-pip

pip install psutil==5.2.2

wget -O /usr/sbin/node_usage.py \
     https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v6/python/node_usage/node_usage.py
```

# Usage: get node status of RAM, CPU and disk
```
# denny@cb-dennyzhang-com:/opt/couchbase/# python /usr/sbin/node_usage.py
{"hostname": "cb-dennyzhang-com", "cpu_count": 12, "ram": {"used_percentage": "96.98%(30.47gb/31.42gb)", "ram_buffers_gb": "0.08", "ram_available_gb": "0.57", "ram_total_gb": "31.42", "ram_used_gb": "30.47"}, "ipaddress_eth0": "165.227.9.21", "disk": {"disk_0": {"free_gb": "91.19", "total_gb": "314.87", "partition": "/", "used_percentage": "66.91%", "used_gb": "210.68"}, "free_gb": "91.19", "total_gb": "314.87", "used_percentage": "/ 66.91%(210.68gb/314.87gb)", "used_gb": "210.68"}, "cpu_load": "0.28 0.51 0.50 2/440 9653"}
```

# Usage: get more status: tail log files, and service status
```
# denny@cb-dennyzhang-com:/opt/couchbase/# python /usr/sbin/node_usage.py --check_service_command "service couchbase-server status" --log_file /var/log/syslog
{"hostname": "cb-dennyzhang-com", "cpu_count": 12, "ram": {"used_percentage": "96.98%(30.47gb/31.42gb)", "ram_buffers_gb": "0.08", "ram_available_gb": "0.57", "ram_total_gb": "31.42", "ram_used_gb": "30.47"}, "ipaddress_eth0": "165.227.9.21", "disk": {"disk_0": {"free_gb": "91.19", "total_gb": "314.87", "partition": "/", "used_percentage": "66.91%", "used_gb": "210.68"}, "free_gb": "91.19", "total_gb": "314.87", "used_percentage": "/ 66.91%(210.68gb/314.87gb)", "used_gb": "210.68"}, "cpu_load": "0.28 0.51 0.50 2/440 9653", "service_status": "service couchbase-server status:\n * couchbase-server is running\n", "tail_log_file": "tail -n 30 /var/log/syslog:\n\"Jul 17 21:52:46 dennyzhang.com kernel: [4954127.984916] [UFW
BLOCK] IN=eth0 OUT= MAC=ca:d3:8f:7d:dc:65:30:7c:5e:93:1c:70:08:00 SRC=117.218.35.177 DST=165.227.8.68 LEN=40 TOS=0x00 PREC=0x00 TTL=236 ID=61862 PRO..."}
```
