#!/bin/bash
set -e
set -x

export NEXTCLOUD_ROOT=/var/www

ARCHIVE_NAME=nextcloud-20.0.4.tar.bz2

# Download and unpack latest nextcloud version in /var/www/
sudo wget https://download.nextcloud.com/server/releases/$ARCHIVE_NAME -P $NEXTCLOUD_ROOT/
sudo tar -xvf $NEXTCLOUD_ROOT/$ARCHIVE_NAME -C $NEXTCLOUD_ROOT/
sudo rm $NEXTCLOUD_ROOT/$ARCHIVE_NAME
sudo chown -R www-data:www-data $NEXTCLOUD_ROOT/nextcloud/ # Set owner

set +x
