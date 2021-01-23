#!/bin/bash
set -e
set -x

NEXTCLOUD_DIR=/var/www/nextcloud

SOURCE_BASE_DIR=/mnt/hdd1 # Root directory of data to back up
USER_NAMES="lars jenny" # Space separated list of users to back up data for
REMOTE_HOST= # <username>@<hostname>/ (empty for local backup)
DEST_ROOT_DIR=/mnt/backup1
DEST_DIR_NAME=duplicity_backup
DEST_BASE_DIR=$DEST_ROOT_DIR/$DEST_DIR_NAME # Directory on remote host where backups shall be stored

LOG_ROOT_DIR=/var/log/duplicity
LOG_FILE=$LOG_ROOT_DIR/duplicity.log

BACKUP_TIME="0 2 * * *" # In crontab format

# Install duplicity
sudo apt -y install duplicity

# Check if backup is remote or local
if [[ ! -z REMOTE_HOST ]]
then
    # User rsync protocol for remote file transfer
    PROTOCOL=rsync://

    # Create SSH key and copy to remote to enable passwordless connection
    ssh-keygen
    ssh-copy-id $REMOTE_HOST
else
    # Set protocol empty if the backup is local
    $PROTOCOL=file://
fi

# Create directory for backup log
sudo mkdir -p $LOG_ROOT_DIR

# Configure rotation of backup log
echo "$LOG_FILE {
    missingok
    weekly
    rotate 10
    compress
    notifempty
}" | sudo tee -a /etc/logrotate.conf

for NAME in $USER_NAMES; do
    SOURCE_DIR=$SOURCE_BASE_DIR/$NAME/files

    # Create README and copy to remote backup directory
    mkdir -p ~/.duplicity_tmp/$NAME
    echo "Backup performed with Duplicity (http://duplicity.nongnu.org/).

RESTORING BACKUP:
Connect the hard drive to a machine.

On Windows 10:
1. Activate the Windows Subsystem for Linux (https://www.windowscentral.com/install-windows-subsystem-linux-windows-10) and install Ubuntu from Microsoft Store.
2. Open the Ubuntu terminal.
2. Install Duplicity:
    sudo apt install duplicity
3. Restore files:
    sudo mkdir /mnt/c/Users/<your username>/restored_backup_$NAME
    sudo duplicity --no-encryption file:///mnt/<hard drive letter, e.g. d>/$DEST_DIR_NAME/$NAME /mnt/c/Users/<your username>/restored_backup_$NAME

On Linux:
1. Install Duplicity:
    sudo apt install duplicity
2. Mount the hard drive:
    sudo mkdir -p $DEST_ROOT_DIR
    sudo mount -t ntfs-3g /dev/<device, e.g. sdb1> $DEST_ROOT_DIR
3. Restore files:
    mkdir ~/restored_backup_$NAME
    sudo duplicity --no-encryption file://$DEST_BASE_DIR/$NAME ~/restored_backup_$NAME
" > ~/.duplicity_tmp/$NAME/README.txt
    rsync -a ~/.duplicity_tmp/$NAME $REMOTE_HOST/$DEST_BASE_DIR/
    rm -r ~/.duplicity_tmp

    # Add backup command to crontab file
    (sudo crontab -l; echo "$BACKUP_TIME sudo -u www-data php $NEXTCLOUD_DIR/occ maintenance:mode --on 2&>1 >> $LOG_FILE && duplicity --log-file=$LOG_FILE --verbosity=info --tempdir=$SOURCE_BASE_DIR/.duplicity/tmp --archive-dir=$SOURCE_BASE_DIR/.duplicity/.cache --name=$NAME --no-encryption $SOURCE_DIR ${PROTOCOL}${REMOTE_HOST}${DEST_BASE_DIR}/$NAME 2&>1 > /dev/null && sudo -u www-data php $NEXTCLOUD_DIR/occ maintenance:mode --off 2&>1 >> $LOG_FILE" ) | sudo crontab -
done
