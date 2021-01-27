#!/bin/bash
set -e
set -x

NEXTCLOUD_DIR=/var/www/nextcloud

SOURCE_BASE_DIR=/mnt/hdd1 # Root directory of data to back up
USER_NAMES="lars jenny" # Space separated list of users to back up data for
REMOTE_HOST= # <username>@<hostname> (empty for local backup)
DEST_ROOT_DIR=/mnt/ulverudskyen_backup
DEST_DIR_NAME=ulverudskyen_backup
DEST_BASE_DIR=$DEST_ROOT_DIR/$DEST_DIR_NAME # Directory on remote host where backups shall be stored

LOG_ROOT_DIR=/var/log/duplicacy
LOG_FILE=$LOG_ROOT_DIR/duplicacy.log

BACKUP_TIME="0 2 * * *" # In crontab format

# Install duplicacy
DUPLICACY_VERSION=2.7.2
wget https://github.com/gilbertchen/duplicacy/releases/download/v${DUPLICACY_VERSION}/duplicacy_linux_arm_${DUPLICACY_VERSION}
chmod a+x duplicacy_linux_arm_${DUPLICACY_VERSION}
sudo mv duplicacy_linux_arm_${DUPLICACY_VERSION} /usr/bin/
sudo ln -sf /usr/bin/duplicacy_linux_arm_${DUPLICACY_VERSION} /usr/bin/duplicacy

# Check if backup is remote or local
if [[ ! -z $REMOTE_HOST ]]
then
    # User rsync protocol for remote file transfer
    PROTOCOL=sftp://

    REMOTE_HOST_SLASH=$REMOTE_HOST/
    REMOTE_HOST_COLON=$REMOTE_HOST:

    SSH_KEYFILE=~/.ssh/backup_id_rsa

    # Create SSH key and copy to remote to enable passwordless connection
    ssh-keygen -N '' -f $SSH_KEYFILE
    ssh-copy-id -i $SSH_KEYFILE $REMOTE_HOST
else
    # Set protocol and remote host variables empty if the backup is local
    PROTOCOL=
    REMOTE_HOST_SLASH=
    REMOTE_HOST_COLON=
fi

# Create directory for backup log
sudo mkdir -p $LOG_ROOT_DIR
sudo chown admin $LOG_ROOT_DIR

# Configure rotation of backup log
if [[ -z $(grep "$LOG_FILE {" /etc/logrotate.conf) ]]; then
    echo "
$LOG_FILE {
    missingok
    weekly
    rotate 10
    compress
    notifempty
}" | sudo tee -a /etc/logrotate.conf
fi

echo "#!/bin/bash
sudo -u www-data php $NEXTCLOUD_DIR/occ maintenance:mode --on
for NAME in $USER_NAMES; do
    cd $SOURCE_BASE_DIR/\$NAME/files
    export declare DUPLICACY_\${NAME^^}_SSH_KEY_FILE=$SSH_KEYFILE
    if [[ ! -d \".duplicacy\" ]]; then
        duplicacy -v -log init -storage-name \$NAME \$NAME ${PROTOCOL}${REMOTE_HOST_SLASH}${DEST_BASE_DIR}/\$NAME
    fi
    duplicacy -v -log backup -storage \$NAME -stats
done
sudo -u www-data php $NEXTCLOUD_DIR/occ maintenance:mode --off" | sudo tee /usr/sbin/backup_nextcloud
sudo chmod a+x /usr/sbin/backup_nextcloud

for NAME in $USER_NAMES; do
    mkdir -p ~/.duplicacy_tmp/$DEST_DIR_NAME/$NAME
    cd ~/.duplicacy_tmp

    # Create README and copy to remote backup directory
    echo "Backup performed with Duplicacy (https://duplicacy.com/).

RESTORING BACKUP:
Connect the hard drive to a machine.

On Windows:
1. Download the Duplicacy installer for Windows from here: https://duplicacy.com/download.html
2. Run the downloaded installer.
3. Enter a new password (will not be used).
4. Click \"STORAGE\" on the left-hand side. Enter the following for the directory:
    <drive letter, e.g. D>:/$DEST_DIR_NAME/$NAME
5. Click \"Continue\".
6. Enter \"$NAME\" for the storage name, and click \"Add\".
7. Click \"RESTORE\" on the left-hand side, and select \"$NAME\" for \"Backup IDs\".
8. Select the revision you want to restore from the \"Revision\" drop-down list.
9. In the \"Restore to\" field, enter:
    C:/<directory to restore to, e.g. Users/$NAME/restored_backup_$NAME>
10. Go to the file explorer and create the directory you want to restore to.
11. Click on the revision you want to restore in the list above the \"Restore\" button.
12. Click the \"Restore\" button.

On Linux:
1. Mount the hard drive:
    sudo mkdir -p $DEST_ROOT_DIR
    sudo mount -t ntfs-3g /dev/<device, e.g. sda1> $DEST_ROOT_DIR
2. Create a new folder for the restored files:
    mkdir ~/restored_backup_$NAME
    cd ~/restored_backup_$NAME
3. Download the Duplicati executable:
    wget https://github.com/gilbertchen/duplicacy/releases/download/v${DUPLICACY_VERSION}/duplicacy_linux_x64_${DUPLICACY_VERSION}
    chmod +x duplicacy_linux_x64_${DUPLICACY_VERSION}
    ln -s duplicacy_linux_x64_${DUPLICACY_VERSION} duplicacy
4. Print backup history and find the number of the revision you want to restore:
    sudo duplicacy init $NAME $DEST_BASE_DIR/$NAME
    sudo duplicacy list
5. Restore files:
    sudo duplicacy restore -r <number of the revision to restore>
" > $DEST_DIR_NAME/$NAME/README.txt
    rsync -a --relative $DEST_DIR_NAME/$NAME ${REMOTE_HOST_COLON}$DEST_ROOT_DIR/
done

rm -r ~/.duplicacy_tmp

# Add backup command to crontab file
(sudo crontab -l; echo "$BACKUP_TIME backup_nextcloud 2>&1 >> $LOG_FILE" ) | sudo crontab -

echo "To backup now, run the following command:
sudo backup_nextcloud 2>&1 | tee -a $LOG_FILE"
