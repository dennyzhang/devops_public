#!/usr/bin/python
##-------------------------------------------------------------------
## File : docker_backup_mysql.py
## Author : Denny <contact@dennyzhang.com>
## Description :
## --
## Created : <2017-03-03>
## Updated: Time-stamp: <2017-09-04 18:55:32>
##-------------------------------------------------------------------
import os, sys
import subprocess
import argparse
import time
from datetime import datetime

################################################################################
# TODO: move to common library
def create_dir_if_missing(directory):
    if not os.path.exists(directory):
        print("directory(%s) doesn't exist. Create it now")
        os.makedirs(directory)

def list_disk_usage():
    # TODO: better way to achieve this
    command = "df -h | grep -v 'tmpfs'"
    print(command)
    # TODO: simplify the code block, running shell command
    p = subprocess.Popen(command, shell=True, stderr=subprocess.PIPE)
    while True:
        out = p.stderr.read(1)
        if out == '' and p.poll() != None:
            break
        # TODO: enable error handling
        if out != '':
            sys.stdout.write(out)
            sys.stdout.flush()

def list_directory(directory):
    # TODO: better way to implement this
    command = "ls -lth %s" % (directory)
    print(command)
    # TODO: simplify the code block, running shell command
    p = subprocess.Popen(command, shell=True, stderr=subprocess.PIPE)
    while True:
        out = p.stderr.read(1)
        if out == '' and p.poll() != None:
            break
        if out != '':
            sys.stdout.write(out)
            sys.stdout.flush()
################################################################################

def docker_backup_mysql(container_name, db_name, db_username, \
                        db_passwd, dst_fname):
    # https://gist.github.com/spalladino/6d981f7b33f6e0afe6bb
    has_error = False
    backup_command = "/usr/bin/mysqldump -u %s --password=%s %s > %s" \
                     % (db_username, db_passwd, db_name, dst_fname)
    command = "docker exec %s %s" % (container_name, backup_command)
    print("In container(%s), run mysqldump for db(%s)" % (container_name, db_name))
    print("command: %s" % (command))
    # TODO: simplify the code block, running shell command
    returncode = subprocess.call(command, shell=True, stderr=subprocess.PIPE)
    print("returncode: %s" % (returncode))
    if returncode != 0:
        has_error = True
    return has_error

def get_backup_fname(dst_dir, db_name, fname_postfix =".sql"):
    return  "%s/db-%s-%s%s" % (dst_dir, db_name, \
                               datetime.now().strftime('%Y-%m-%d-%H%M%S'), \
                               fname_postfix)

def backup_db(container_name, db_name, db_username, \
              db_passwd, dst_dir):
    create_dir_if_missing(dst_dir)
    dst_fname = get_backup_fname(dst_dir, db_name)
    print("List disk usage, before backup")
    list_disk_usage()
    print("List existing backupset, before backup")
    list_directory(dst_dir)

    has_error = docker_backup_mysql(container_name, db_name, db_username, \
                                    db_passwd, dst_fname)
    if has_error is True:
        return has_error

    print("List existing backupset, after backup")
    # TODO: If free disk in docker host lower than 15%, the job will be marked as failed.
    list_disk_usage()

    print("List existing backupset, after backup")
    list_directory(dst_dir)
    return has_error

if __name__ == '__main__':
    '''
    python ./docker_backup_mysql.py --container_name docker \
            --db_name db1 --db_username username1 --db_passwd password1 \
            --dst_dir /data/backup/mysql
    '''
    parser = argparse.ArgumentParser()
    parser.add_argument('--container_name', required=True, \
                        help="Docker container name of DB", type=str)
    parser.add_argument('--db_name', required=True, \
                        help="DB name", type=str)
    parser.add_argument('--db_username', required=True, \
                        help="Username to login db", type=str)
    parser.add_argument('--db_passwd', required=True, \
                        help="Password to login db", type=str)
    parser.add_argument('--dst_dir', required=True, \
                        help="Folder to save backupset", type=str)
    l = parser.parse_args()

    has_error = backup_db(l.container_name, l.db_name, l.db_username, l.db_passwd, l.dst_dir)
    if has_error is True:
        print("ERROR: db backup has failed.")
        sys.exit(1)
    else:
        print("OK: db backup has succeeded.")
## File : docker_backup_mysql.py ends
