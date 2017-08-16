# S3Sync
Check more: https://www.dennyzhang.com/sync_s3_directory

Sync a directory to/from S3 bucket

How To Use
==============
- Setup aws cli: pip install awscli and customize  ~/.aws/config, ~/.aws/credentials
- git clone https://github.com/DennyZhang/S3Sync.git
- Try Backup
```
./s3sync.sh backup /etc/apache2 denny-bucket2 s3backup/test
Backup /etc/apache2 to s3://denny-bucket2/s3backup/test
```
- Try Restore
```
 ./s3sync.sh restore /tmp/apache2 denny-bucket2 s3backup/test
Restore s3://denny-bucket2/s3backup/test to /tmp/apache2
```