check_proc_cpu
==============

- Link: https://www.dennyzhang.com/nagois_monitor_process_cpu/
- Code: https://github.com/DennyZhang/devops_public/tree/tag_v6/nagios_plugins/check_proc_cpu

Nagios plugin to check proc cpu usage.

```
/sshx:denny@dennyzhang.com: #$ ./check_proc_cpu.sh --help
check_proc_cpu v1.0

Usage:
./check_proc_cpu.sh -w <warn_cpu> -c <criti_cpu> <pid_pattern> <pattern_argument>

Below: If tomcat use more than 200% CPU, send warning.
Note machines may have multiple cpu cores
check_proc_cpu.sh -w 200 -c 400 --pidfile /var/run/tomcat7.pid
check_proc_cpu.sh -w 200 -c 400 --pid 11325
check_proc_cpu.sh -w 200 -c 400 --cmdpattern "tomcat7.*java.*Dcom"

Copyright (C) 2015 DennyZhang (denny@dennyzhang.com)
```

Sample output:
```
/sshx:denny@dennyzhang.com: #$ ./check_proc_cpu.sh -w 1024 -c 2048 --pidfile "/var/run/tomcat7.pid"
OK CPU used by process(11325) is 10 %|CPU=10
```
