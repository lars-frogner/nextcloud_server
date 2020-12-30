#!/bin/bash
set -e

export NEXTCLOUD_ROOT=/var/www

set -x

# Download and unpack latest nextcloud version in /var/www/
sudo wget https://download.nextcloud.com/server/releases/latest.tar.bz2 -P $NEXTCLOUD_ROOT/
sudo tar -xvf $NEXTCLOUD_ROOT/latest.tar.bz2 -C $NEXTCLOUD_ROOT/
sudo rm $NEXTCLOUD_ROOT/latest.tar.bz2
sudo chown -R www-data:www-data $NEXTCLOUD_ROOT/nextcloud/ # Set owner
