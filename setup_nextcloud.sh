#!/bin/bash
set -e

PASSWORD=${1?"Usage: $0 <password>"}

set -v

HOST_IP=$(host raspberrypi | sed -n "s/^.*has address \([0-9\.]*\).*$/\1/p")
PUBLIC_IP=$(curl ifconfig.me)

NEXTCLOUD_DIR=$NEXTCLOUD_ROOT/nextcloud

# Install nextcloud for admin user
sudo -u www-data php $NEXTCLOUD_DIR/occ maintenance:install --admin-user admin --admin-pass $PASSWORD --data-dir=$PRIMARY_STORAGE --database mysql --database-name nextcloud --database-user admin --database-pass $PASSWORD

# Add trusted domains for accessing nextcloud
sudo -u www-data php $NEXTCLOUD_DIR/occ config:system:set trusted_domains 1 --value=$HOST_IP
sudo -u www-data php $NEXTCLOUD_DIR/occ config:system:set trusted_domains 2 --value=$PUBLIC_IP
if [ ! -z "$DOMAIN_NAME" ]
  then
    sudo -u www-data php $NEXTCLOUD_DIR/occ config:system:set trusted_domains 3 --value=$DOMAIN_NAME
fi

# Enable External storages app
#sudo -u www-data php $NEXTCLOUD_DIR/occ app:enable files_external

# Install two-factor authentication app
sudo -u www-data php $NEXTCLOUD_DIR/occ app:install twofactor_totp

# Update config.php to get prettier URLs
sudo sed -i "s/'overwrite.cli.url' => 'http:\/\/localhost',/'overwrite.cli.url' => 'https:\/\/$DOMAIN_NAME\/nextcloud',/g" $NEXTCLOUD_DIR/config/config.php
sudo sed -i "/);/i \ \ 'htaccess.RewriteBase' => '\/nextcloud'," $NEXTCLOUD_DIR/config/config.php

# Update .htaccess file after changing config.php
sudo -u www-data php $NEXTCLOUD_DIR/occ maintenance:update:htaccess

# Add convenient occ alias to bashrc
echo "
alias occ='sudo -u www-data php $NEXTCLOUD_DIR/occ'" | sudo -u admin tee -a $ADMIN_HOME/.bashrc
