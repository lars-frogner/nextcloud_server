#!/bin/bash
set -e
set -x

HDD1_MOUNT_POINT=/mnt/hdd1
export PRIMARY_STORAGE=$HDD1_MOUNT_POINT

# Install packages for NTFS compatibility
sudo apt -y install fuse
sudo apt -y install ntfs-3g

# Install packages for exFAT compatibility
sudo apt -y install exfat-fuse exfat-utils

# Mount external hard drive
HDD1=$(sudo blkid | grep 'TYPE="ntfs"' | head -n 1 | sed -n "s/^\(.*\):.*$/\1/p")
sudo mkdir -p $HDD1_MOUNT_POINT
echo "$HDD1 $HDD1_MOUNT_POINT ntfs-3g nofail,nobootwait,uid=$(id -u www-data),gid=$(id -g www-data),umask=027 0       2" | sudo tee -a /etc/fstab
sudo mount -a
