#!/bin/bash
set -e
set -x

SOURCE_BASE_DIR=/mnt/hdd1 # Root directory of data to back up
USER_NAMES="lars jenny" # Space separated list of users to back up data for
REMOTE_HOST= # <username>@<hostname>/ (empty for local backup)
DEST_ROOT_DIR=/mnt/backup1
DEST_BASE_DIR=$DEST_ROOT_DIR/duplicity_backup # Directory on remote host where backups shall be stored

LOG_ROOT_DIR=/var/log/duplicity
LOG_FILE=$LOG_ROOT_DIR/duplicity.log

BACKUP_TIME="0 6 * * *" # In crontab format

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

On Windows:
Use Duplicati (https://www.duplicati.com).

On Linux:
1. Install Duplicity:
    sudo apt install duplicity
2. Mount the hard drive:
    sudo mkdir -p $DEST_ROOT_DIR
    sudo mount -t ntfs-3g /dev/<device> $DEST_ROOT_DIR
3. Restore files:
    mkdir ~/restored_backup
    sudo duplicity --no-encryption file://$DEST_BASE_DIR/$NAME ~/restored_backup
" > ~/.duplicity_tmp/$NAME/README.txt
    rsync -a ~/.duplicity_tmp/$NAME $REMOTE_HOST/$DEST_BASE_DIR/
    rm -r ~/.duplicity_tmp

    # Add backup command to crontab file
    (sudo crontab -l; echo "$BACKUP_TIME sudo duplicity --log-file=$LOG_FILE --no-encryption $SOURCE_DIR ${PROTOCOL}${REMOTE_HOST}${DEST_BASE_DIR}/$NAME" ) | sudo crontab -
done
