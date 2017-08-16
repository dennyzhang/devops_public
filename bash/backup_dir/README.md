# backup_dir
Check more: https://www.dennyzhang.com/howto_backup_directory

By default, backup_dir.sh will backup file and directories:
- Backup file list specified by backup_dir.rc
- Compress backup set
- Delete backupset older than 10 days for date retention.
- Log any error messsages to /var/log/backup_dir.log

How To Use
==========
1. copy backup_dir.rc.sample to backup_dir.rc
2. Customize backup_dir.rc, especially BACKUP_DIR parameter
3. sudo ./backup_dir.sh ./backup_dir.rc
```
macs-MacBook-Air:backup_dir mac$ sudo ./backup_dir.sh ./backup_dir.rc
[2015-05-07 01:17:09] ########## Begin Backup. Logfile: README.md #################
[2015-05-07 01:17:09] backup files and directories
[2015-05-07 01:17:09] cp -r /etc/hosts /data/backup/myproject.20150507.011709//etc/
[2015-05-07 01:17:09] cp -r /etc/sudoers /data/backup/myproject.20150507.011709//etc/
[2015-05-07 01:17:09] cp -r /etc/apache2/extra /data/backup/myproject.20150507.011709//etc/apache2/
[2015-05-07 01:17:09] Track time spent: Backup step takes 0 seconds
[2015-05-07 01:17:09] Compress backup set to archive packages
[2015-05-07 01:17:09] tar -zcf myproject.20150507.011709.tar.gz myproject.20150507.011709
[2015-05-07 01:17:09] rm -rf myproject.20150507.011709
[2015-05-07 01:17:09] Track time spent: Compress step takes 0 seconds
[2015-05-07 01:17:09] Data retention for old backup set
[2015-05-07 01:17:09] find /data/backup -name "*.gz" -mtime +10 -and -not -type d -delete
[2015-05-07 01:17:09] Track time spent: Data Retention step takes 0 seconds
[2015-05-07 01:17:09] Backup operation is done
[2015-05-07 01:17:09] ########## Backup operation is done #############################
```
