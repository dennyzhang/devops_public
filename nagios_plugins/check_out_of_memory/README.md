check_proc_fd
==============

- Link: https://www.dennyzhang.com/monitor_oom
- Code: https://github.com/DennyZhang/devops_public/tree/tag_v6/nagios_plugins/check_out_of_memory

Nagios plugin to check whether OOM issues have happend

Sample output:
```
/sshx:contact@dennyzhang.com:~# python /tmp/check_out_of_memory.py --hours_to_check 100
ERROR: OOM has happened in previous 100 hours.
[Sat Mar 11 00:19:43 2017] java invoked oom-killer: gfp_mask=0x26000c0, order=2, oom_score_adj=-17
[Sat Mar 11 00:19:43 2017]  [<ffffffff81188b35>] oom_kill_process+0x205/0x3d0
[Sat Mar 11 00:19:43 2017] [ pid ]   uid  tgid total_vm      rss nr_ptes nr_pmds swapents oom_score_adj name
/sshx:contact@dennyzhang.com:~# python /tmp/check_out_of_memory.py --hours_to_check 10
OK: No OOM has happened in previous 10 hours.
```
