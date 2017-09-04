#!/bin/bash -e
##-------------------------------------------------------------------
## File : s3sync.sh
## Author : Denny <contact@dennyzhang.com>
## Description :
## --
## Created : <2015-05-12>
## Updated: Time-stamp: <2017-09-04 18:54:43>
##-------------------------------------------------------------------
# action: backup or restore
. /etc/profile
action=${1:-"backup"}
local_dir=${2:-"/etc/apache2"}

# local files will sync to s3://$bucket_name/$bucket_dir/$local_dir/...
bucket_name=${3:-"denny-bucket2"}
bucket_dir=${4:-"s3backup/test"}

# Metadata track what files have been uploaded to S3
metadata_file=${5:-"/tmp/metadata.txt"}
verbose=${6:-true}
# paralle_count=${7:-2}

function backup_to_s3() {
    set -e
    local metadata_file=${1?}
    local local_dir=${2?}
    local bucket_name=${3?}
    local bucket_dir=${4?}
    local full_fname
    if [ -f "$local_dir" ]; then
        # backup file
        full_fname=$local_dir
        command="aws s3 cp $full_fname s3://$bucket_name/${bucket_dir}${full_fname}"
        echo "$command"
        "$command"
        echo "$full_fname" >> "$metadata_file"
    else
        # backup directory
        for f in $local_dir; do
            [[ -e $f ]] || break
            full_fname="$local_dir/$f"
            if [ -d "$full_fname" ]; then
                cd "$full_fname"
                backup_to_s3 "$metadata_file" "$full_fname" "$bucket_name" "$bucket_dir"
            else
                if grep "$full_fname" "$metadata_file" 1>/dev/null; then
                    if $verbose; then
                        echo "skip $full_fname"
                    fi
                else
                    command="aws s3 cp $full_fname s3://$bucket_name/${bucket_dir}${full_fname}"
                    echo "$command"
                    "$command"
                    echo "$full_fname" >> "$metadata_file"
                fi
            fi
        done
    fi
}

function restore_from_s3() {
    set -e
    local metadata_file=${1?}
    local local_dir=${2?}
    local bucket_name=${3?}
    local bucket_dir=${4?}
    local full_fname
    while IFS= read -r full_fname
    do
        command="aws s3 cp s3://$bucket_name/${bucket_dir}${full_fname} ${local_dir}${full_fname}"
        echo "$command"
        "$command"
    done < <(cat "$metadata_file")
}

[ -f "$metadata_file" ] || touch "$metadata_file"

# Test
# ./s3sync.sh backup /etc/apache2 denny-bucket2 s3backup/test /tmp/metadata.txt
# ./s3sync.sh restore /tmp/apache2 denny-bucket2 s3backup/test /tmp/metadata.txt
echo "========================================================"
if [ "$action" = "backup" ]; then
    echo "Backup $local_dir to s3://$bucket_name/$bucket_dir. metadatafile - $metadata_file"
    backup_to_s3 "$metadata_file" "$local_dir" "$bucket_name" "$bucket_dir"
else
    echo "Restore s3://$bucket_name/$bucket_dir to $local_dir. metadatafile - $metadata_file"
    restore_from_s3 "$metadata_file" "$local_dir" "$bucket_name" "$bucket_dir"
fi
## File : s3sync.sh ends
