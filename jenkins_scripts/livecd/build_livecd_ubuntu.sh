#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : build_livecd_ubuntu.sh
## Author : DennyZhang.com <contact@dennyzhang.com>
## Description :
## --
## Created : <2016-01-05>
## Updated: Time-stamp: <2017-09-04 18:54:38>
##-------------------------------------------------------------------

# How to build liveCD of ubuntu: http://customizeubuntu.com/ubuntu-livecd
# Note: above instruction only support desktop version of ubuntu, instead of server version
################################################################################################
. /etc/profile
[ -n "$DOWNLOAD_TAG_NAME" ] || export DOWNLOAD_TAG_NAME="tag_v6"
export DOWNLOAD_PREFIX="https://raw.githubusercontent.com/DennyZhang/devops_public/${DOWNLOAD_TAG_NAME}"
if [ ! -f /var/lib/devops/refresh_common_library.sh ]; then
    [ -d /var/lib/devops/ ] || (sudo mkdir -p /var/lib/devops/ && sudo chmod 777 /var/lib/devops)
    wget -O /var/lib/devops/refresh_common_library.sh "$DOWNLOAD_PREFIX/common_library/refresh_common_library.sh"
    chmod 777 /var/lib/devops/refresh_common_library.sh
fi
bash /var/lib/devops/refresh_common_library.sh "3536991806" "/var/lib/devops/devops_common_library.sh" \
     "${DOWNLOAD_PREFIX}/common_library/devops_common_library.sh"
. /var/lib/devops/devops_common_library.sh
################################################################################################
working_dir=${1:-"/root/work/"}
fetch_iso_url=${2:-"http://releases.ubuntu.com/14.04/ubuntu-14.04.3-desktop-amd64.iso"}
livecd_image_name=${3:-"my-ubuntu-14.04.3.iso"}
volume_id=${4:-"DevOps Ubuntu"}

function umount_dir()
{
    local dir=${1?}

    if [ -d "$dir" ]; then
        fs_name=$(stat --file-system --format="%T" "$dir")
        if [ "$fs_name" = "tmpfs" ] || [ "$fs_name" = "isofs" ]; then
            umount "$dir"
        fi
    fi
}

function original_ubuntu_iso() {
    local working_dir=${1?}
    local short_iso_filename
    short_iso_filename=$(basename "$fetch_iso_url")
    echo "$working_dir/../$short_iso_filename"
}

function livecd_clean_up() {
    umount_dir "$working_dir/mnt"
    umount_dir "$working_dir/edit/dev"
}

function clean_up_dev_mount() {
    local working_dir=${1?}
    if [ -d "$working_dir/edit" ]; then
        fs_name=$(stat --file-system --format="%T" /dev)
        if [ "$fs_name" = "tmpfs" ] || [ "$fs_name" = "isofs" ]; then
            cd "$working_dir"
            chroot edit umount /proc || true
            chroot edit umount /sys || true
            chroot edit umount /dev/pts || true
            umount edit/dev || true
        fi
    fi
}

function customize_ubuntu_image() {
    set -e
    log "Customize Image"
    local chroot_dir=${1?}

    log "change /etc/resolv.conf"
    chroot "$chroot_dir" bash -c "echo nameserver 8.8.8.8 > /etc/resolv.conf"
    log "apt-get -y update"
    chroot "$chroot_dir" bash -c "apt-get -y update" 1>/dev/null
    chroot "$chroot_dir" bash -c "apt-get install -y tmux vim openssh-server" 1>/dev/null

    log "Install docker. This may take several minutes"
    chroot "$chroot_dir" bash -c "wget -qO- https://get.docker.com/ | sh"

    # log "Enable docker autostart"
    # chroot "$chroot_dir" bash -c "update-rc.d docker defaults"
    # chroot "$chroot_dir" bash -c "update-rc.d docker enable"
}

############################################################################
# Make sure the script is run in right OS
if [[ "$(os_release)" != "ubuntu" ]]; then
    echo "Error: This script can only run in ubuntu OS." 1>&2
    exit 1
fi

# Make sure the script is run as a root
fail_unless_root
trap livecd_clean_up SIGHUP SIGINT SIGTERM 0

dst_iso="$working_dir/$livecd_image_name"

log "Install necessary packages"
which aptitude 1>/dev/null || apt-get install -y aptitude 1>/dev/null
aptitude install -y squashfs-tools genisoimage 1>/dev/null

rm -rf "$working_dir" && mkdir -p "$working_dir"
cd "$working_dir"
mkdir mnt

ubuntu_iso_full_path=$(original_ubuntu_iso "$working_dir")
if [ ! -f "$ubuntu_iso_full_path" ]; then
    log "Download original ubuntu iso"
    wget -O "$ubuntu_iso_full_path" "$fetch_iso_url"
fi

# mount mnt
clean_up_dev_mount "$working_dir"
log "Mount iso and extract content. This may takes ~30 seconds"
mount -o loop "$(original_ubuntu_iso "$working_dir")" mnt
mkdir extract-cd
rsync --exclude=/casper/filesystem.squashfs -a mnt/ extract-cd

# unsquashfs
unsquashfs mnt/casper/filesystem.squashfs
mv squashfs-root edit

log "Prepare and chroot"
mount --bind /dev/ edit/dev
chroot edit mount -t proc none /proc
chroot edit mount -t sysfs none /sys
chroot edit mount -t devpts none /dev/pts

# chroot edit export HOME=/root
# chroot edit export LC_ALL=C

customize_ubuntu_image "$working_dir/edit"

log "Clean up and umount filesystem"
chroot edit apt-get -y update
chroot edit apt-get install -y aptitude
chroot edit aptitude clean
chroot edit rm -rf /tmp/* ~/.bash_history

# chroot edit rm -rf /etc/resolv.conf
# chroot edit rm -rf /var/lib/dbus/machine-id
# chroot edit rm -rf /sbin/initctl
# chroot edit dpkg-divert --rename --remove /sbin/initctl

chroot edit umount /proc
chroot edit umount /sys
chroot edit umount /dev/pts
umount edit/dev

log "Regenerate Manifest"
chmod +w extract-cd/casper/filesystem.manifest
chroot edit dpkg-query -W --showformat="\${Package} \${Version}\n" > extract-cd/casper/filesystem.manifest
cp extract-cd/casper/filesystem.manifest extract-cd/casper/filesystem.manifest-desktop

sed -i '/ubiquity/d' extract-cd/casper/filesystem.manifest-desktop
sed -i '/casper/d' extract-cd/casper/filesystem.manifest-desktop

log "Compress to SquashFS Filesystem. This shall take several minutes"
[ ! -f extract-cd/casper/filesystem.squashfs ] || rm extract-cd/casper/filesystem.squashfs
mksquashfs edit extract-cd/casper/filesystem.squashfs

log "Update md5sum"
cd extract-cd
rm md5sum.txt
find . -type f -print0 | xargs -0 md5sum | grep -v isolinux/boot.cat | tee md5sum.txt

log "Create ISO image"
mkisofs -r -D -V "$volume_id" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o "$dst_iso" .
log "Build process completed: image can be found in $dst_iso."
## File : build_livecd_ubuntu.sh ends
