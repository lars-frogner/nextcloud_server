#!/bin/bash
set -e
set -x

NEXTCLOUD_DIR=/var/www/nextcloud

SOURCE_BASE_DIR=/mnt/hdd1 # Root directory of data to back up
USER_NAMES="lars jenny" # Space separated list of users to back up data for
REMOTE_HOST= # <username>@<hostname>/ (empty for local backup)
DEST_ROOT_DIR=/mnt/backup1
DEST_DIR_NAME=duplicati_backup
DEST_BASE_DIR=$DEST_ROOT_DIR/$DEST_DIR_NAME # Directory on remote host where backups shall be stored

LOG_ROOT_DIR=/var/log/duplicati
LOG_FILE=$LOG_ROOT_DIR/duplicati.log

BACKUP_TIME="0 2 * * *" # In crontab format

# Install duplicati
sudo apt -y install apt-transport-https nano git-core software-properties-common dirmngr
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
echo "deb http://download.mono-project.com/repo/debian raspbianbuster main" | sudo tee /etc/apt/sources.list.d/mono-official.list
sudo apt -y update
sudo apt -y install mono-devel
DUPLICATI_VERSION=2.0.5.1-1
wget https://updates.duplicati.com/beta/duplicati_${DUPLICATI_VERSION}_all.deb
sudo apt -y install ./duplicati_${DUPLICATI_VERSION}_all.deb

# Check if backup is remote or local
if [[ ! -z REMOTE_HOST ]]
then
    # User rsync protocol for remote file transfer
    PROTOCOL=ssh://

    SSH_KEYFILE=~/.ssh/backup_id_rsa

    # Create SSH key and copy to remote to enable passwordless connection
    ssh-keygen -N '' -f $SSH_KEYFILE
    ssh-copy-id -i $SSH_KEYFILE $REMOTE_HOST

    PROTOCOL_ARGS="--ssh-keyfile=$SSH_KEYFILE"
else
    # Set protocol empty if the backup is local
    PROTOCOL=file://

    PROTOCOL_ARGS=
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
    mkdir -p ~/.duplicati_tmp/$NAME
    echo "Backup performed with Duplicati (https://www.duplicati.com/).

RESTORING BACKUP:
Connect the hard drive to a machine.

On Windows 10:
1. Install Duplicity following these instructions: https://duplicati.readthedocs.io/en/latest/02-installation/

On Linux:
1. Install Duplicity following these instructions: https://duplicati.readthedocs.io/en/latest/02-installation/
2. Mount the hard drive:
    sudo mkdir -p $DEST_ROOT_DIR
    sudo mount -t ntfs-3g /dev/<device, e.g. sdb1> $DEST_ROOT_DIR
3. Restore files:
    mkdir ~/restored_backup_$NAME
    sudo duplicati-cli restore --restore-path=~/restored_backup_$NAME file://$DEST_BASE_DIR/$NAME
" > ~/.duplicati_tmp/$NAME/README.txt
    rsync -a ~/.duplicati_tmp/$NAME $REMOTE_HOST/$DEST_BASE_DIR/
    rm -r ~/.duplicati_tmp

    # Add backup command to crontab file
    (sudo crontab -l; echo "$BACKUP_TIME sudo -u www-data php $NEXTCLOUD_DIR/occ maintenance:mode --on 2&>1 >> $LOG_FILE && duplicati-cli --log-file=$LOG_FILE --log-file-log-level=Verbose backup --no-encryption=true $PROTOCOL_ARGS ${PROTOCOL}${REMOTE_HOST}${DEST_BASE_DIR}/$NAME $SOURCE_DIR 2&>1 > /dev/null && sudo -u www-data php $NEXTCLOUD_DIR/occ maintenance:mode --off 2&>1 >> $LOG_FILE" ) | sudo crontab -
done
