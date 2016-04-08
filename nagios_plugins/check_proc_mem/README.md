check_proc_mem
==============

- Link: http://www.dennyzhang.com/nagois_monitor_process_memory/
- Code: https://github.com/DennyZhang/check_proc_mem

Zabbix plugin to check proc memory: Monitor resident memory for a given process

```
/sshx:denny@dennyzhang.com: #$ ./check_proc_mem.sh --help
check_proc_mem v1.0

Usage:
./check_proc_mem.sh -w <warn_MB> -c <criti_MB> <pid_pattern> <pattern_argument>

Below: If tomcat use more than 1024MB resident memory, send warning
./check_proc_mem.sh -w 1024 -c 2048 --pidfile "/var/run/tomcat7.pid"
./check_proc_mem.sh -w 1024 -c 2048 --pid 11325
./check_proc_mem.sh -w 1024 -c 2048 --cmdpattern "tomcat7.*java.*Dcom"

Copyright (C) 2014 DennyZhang (denny.zhang001@gmail.com)
```

Sample output:
```
/sshx:denny@dennyzhang.com: #$ ./check_proc_mem.sh -w 1024 -c 2048 --pidfile "/var/run/tomcat7.pid"
Memory: OK VIRT: 5795 MB - RES: 663 MB used!|VIRT=6076497920;;;; RES=695205888;;;;
```
