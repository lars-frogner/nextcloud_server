#!/bin/bash
set -e

HDD1_MOUNT_POINT=/mnt/hdd1

set -x

# Install packages for NTFS compatibility
sudo apt -y install fuse
sudo apt -y install ntfs-3g

# Mount external hard drive
HDD1_UUID=$(sudo blkid | grep 'TYPE="ntfs"' | head -n 1 | sed -n "s/^.* UUID=\"\(\S*\)\".*$/\1/p")
sudo mkdir $HDD1_MOUNT_POINT
echo "UUID=$HDD1_UUID $HDD1_MOUNT_POINT ntfs-3g    uid=$(id -u www-data),gid=$(id -g www-data),umask=027 0       2" | sudo tee -a /etc/fstab
sudo mount -a

set +x

echo $HDD1_MOUNT_POINT
