#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : backup_dir.sh
## Author : Denny <contact@dennyzhang.com>
## Description : Backup directory and tar it with timestamp
## --
## Created : <2015-04-21>
## Updated: Time-stamp: <2017-09-04 18:54:44>
##-------------------------------------------------------------------

## Trap exit and dump status
function shell_exit() {
    if [ $? -eq 0 ]; then
        log "Backup operation is done"
        log "########## Backup operation is done #############################"
        echo "State: DONE Timestamp: $(current_time)" >> "$STATUS_FILE"
    else
        log "ERROR: Backup operation fail"
        log "########## ERROR: Backup operation fail #########################"
        echo "State: FAILED Timestamp: $(current_time)" >> "$STATUS_FILE"
        # TODO: send out email
        exit 1
    fi
}
################################################################
function log() {
    local msg=$*
    date_timestamp=$(date +['%Y-%m-%d %H:%M:%S'])
    echo -ne "$date_timestamp $msg\n"

    if [ -n "$LOG_FILE" ]; then
        echo -ne "$date_timestamp $msg\n" >> "$LOG_FILE"
    fi
}

function tar_dir() {
    local dir=${1?}
    local tar_file=${2?}
    working_dir=$(dirname "$dir")
    cd "$working_dir"
    log "tar -zcf $tar_file $(basename "$dir")"
    tar -zcf "$tar_file" "$(basename "$dir")"
}

function current_time() {
    date '+%Y-%m-%d-%H%M%S'
}

function ensure_is_root() {
    # Make sure only root can run our script
    if [[ $EUID -ne 0 ]]; then
        echo "Error: This script must be run as root." 1>&2
        exit 1
    fi
}
################################################################
function backup_dir()
{
    cd "$DST_DIR"
    local backup_list=${$BACKUP_DIR//;/ }
    for item in ${backup_list[*]}; do
        if [ -f "$item" ] || [ -d "$item" ]; then
            dir_name=$(dirname "$item")
            mkdir -p "$DST_DIR/$backup_id/$dir_name/"
            log "cp -r $item $DST_DIR/$backup_id/$dir_name/"
            cp -r "$item" "$DST_DIR/$backup_id/$dir_name/"
        fi
    done;
}

function archieve_backup() {
    set -e
    cd "$DST_DIR"
    tar_dir "$backup_id" "${backup_id}.tar.gz"
    log "rm -rf $backup_id"
    rm -rf "$backup_id"
}

function expire_old_backup() {
    set -e
    cd "$DST_DIR"
    if [ "$RETENTION_DAYS" -eq 0 ]; then
        log "RETENTION_DAYS Parameter is 0, skip backup set retention"
    else
        log "find $DST_DIR -name \"*.gz\" -mtime +$RETENTION_DAYS -and -not -type d -delete"
        find "$DST_DIR" -name "*.gz" -mtime "+$RETENTION_DAYS" -and -not -type d -delete
    fi
}

function set_default_value() {
    [ -n "$BACKUP_DIR" ] || BACKUP_DIR="/etc/hosts;/etc/sudoers;/etc/apache2/extra"
    [ -n "$BACKUP_SET_PREFIX" ] || BACKUP_SET_PREFIX="myproject"
    [ -n "$DST_DIR" ] || DST_DIR=/data/backup
    [ -n "$SHOULD_COMPRESS" ] || SHOULD_COMPRESS="TRUE"
    [ -n "$RETENTION_DAYS" ] || RETENTION_DAYS=10
    [ -n "$BACKUP_LOG_FILE" ] || BACKUP_LOG_FILE="/var/log/ops/backup_dir.log"
    [ -n "$STATUS_FILE" ] || STATUS_FILE="/var/log/backup_dir_state"
}
################################ Main Logic ################################
# method 1:
# sudo ./backup_dir.sh ./backup_dir.rc
#
# method 2:
# export BACKUP_DI="/tmp/backup/"
# sudo ./backup_dir.sh
BACKUP_RC_FILE=${1:-"./backup_dir.rc"}
ensure_is_root
trap shell_exit SIGHUP SIGINT SIGTERM 0

# source file
if [ -f "$BACKUP_RC_FILE" ]; then
    . "$BACKUP_RC_FILE"
fi

set_default_value

if [ -n "$BACKUP_LOG_FILE" ]; then
    log_dir=$(dirname "$BACKUP_LOG_FILE")
    [ -d "$log_dir" ] || mkdir -p "$log_dir"
fi

# Format: +%Y-%m-%d-%H%M%S_$pid
backup_id="$(date '+%Y%m%d.%H%M%S')"
if [ -n "$BACKUP_SET_PREFIX" ]; then
    backup_id="$BACKUP_SET_PREFIX.$backup_id"
fi

log "########## Begin Backup. Logfile: backup_dir.sh #################"
echo "State: BACKUP Timestamp: $(current_time)" >> $STATUS_FILE
if [ -z "$BACKUP_DIR" ]; then
    log "ERROR: BACKUP_DIR parameter must be set"
    exit 1
fi

[ -d $DST_DIR ] || mkdir -p $DST_DIR
log "backup files and directories to $DST_DIR"

START=$(date +%s)
backup_dir
END=$(date +%s)
DIFF=$(echo "$END - $START" | bc)
log "Track time spent: Backup step takes $DIFF seconds"

if [ "$SHOULD_COMPRESS" = "TRUE" ]; then
    echo "State: COMPRESS Timestamp: $(current_time)" >> $STATUS_FILE
    log "Compress backup set to archive packages"
    START=$(date +%s)
    archieve_backup
    END=$(date +%s)
    DIFF=$(echo "$END - $START" | bc)
    log "Track time spent: Compress step takes $DIFF seconds"
fi

echo "State: RETENTION Timestamp: $(current_time)" >> $STATUS_FILE
log "Data retention for old backup set"
expire_old_backup
START=$(date +%s)
END=$(date +%s)
DIFF=$(echo "$END - $START" | bc)
log "Track time spent: Data Retention step takes $DIFF seconds"
## File : backup_dir.sh ends
