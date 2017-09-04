check_java_threadcount
==============
Nagios Monitor thread count of a given program

check_proc_threadcount v1.0

- Link: https://www.dennyzhang.com/nagois_threadcount
- Code: https://github.com/DennyZhang/devops_public/tree/tag_v6/nagios_plugins/check_proc_threadcount

```
Usage:
check_proc_threadcount.sh -w <warn_count> -c <criti_count> <pid_pattern> <pattern_argument>

Below: If tomcat starts more than 1024 threads, send warning
check_proc_threadcount.sh -w 1024 -c 2048 --pidfile /var/run/tomcat7.pid
check_proc_threadcount.sh -w 1024 -c 2048 --pid 11325
check_proc_threadcount.sh -w 1024 -c 2048 --cmdpattern "tomcat7.*java.*MaxPermSize"

Copyright (C) 2017 DennyZhang (contact@dennyzhang.com)
```
