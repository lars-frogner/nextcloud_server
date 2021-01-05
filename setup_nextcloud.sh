#!/bin/bash
set -e

PASSWORD=${1?"Usage: $0 <password>"}

set -v

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

# Disable unwanted default apps
sudo -u www-data php $NEXTCLOUD_DIR/occ app:disable survey_client
sudo -u www-data php $NEXTCLOUD_DIR/occ app:disable dashboard

# Enable External storages app
sudo -u www-data php $NEXTCLOUD_DIR/occ app:enable files_external

# Enable Default Encryption Module app
#sudo -u www-data php $NEXTCLOUD_DIR/occ app:enable encryption

# Install two-factor authentication app
sudo -u www-data php $NEXTCLOUD_DIR/occ app:install twofactor_totp
sudo -u www-data php $NEXTCLOUD_DIR/occ app:install twofactor_admin

sudo -u www-data php $NEXTCLOUD_DIR/occ app:install ransomware_protection

# Install Duplicate Finder
sudo -u www-data php $NEXTCLOUD_DIR/occ app:install duplicatefinder

# Install Breeze Dark theme
sudo -u www-data php $NEXTCLOUD_DIR/occ app:install breezedark

# Install Camera RAW Previews
sudo -u www-data php $NEXTCLOUD_DIR/occ app:install camerarawpreviews

# Install integration apps
sudo -u www-data php $NEXTCLOUD_DIR/occ app:install integration_dropbox
sudo -u www-data php $NEXTCLOUD_DIR/occ app:install integration_google
sudo -u www-data php $NEXTCLOUD_DIR/occ app:install integration_onedrive

# Install disk quota warning app
sudo -u www-data php $NEXTCLOUD_DIR/occ app:install quota_warning

# Install media apps
sudo -u www-data php $NEXTCLOUD_DIR/occ app:install extract
sudo -u www-data php $NEXTCLOUD_DIR/occ app:install audioplayer
sudo -u www-data php $NEXTCLOUD_DIR/occ app:install epubreader
sudo -u www-data php $NEXTCLOUD_DIR/occ app:install notes
sudo -u www-data php $NEXTCLOUD_DIR/occ app:install pdfdraw
sudo -u www-data php $NEXTCLOUD_DIR/occ app:install files_readmemd

# Install and configure Preview Generator
sudo -u www-data php $NEXTCLOUD_DIR/occ app:install previewgenerator
sudo -u www-data php $NEXTCLOUD_DIR/occ config:app:set previewgenerator squareSizes --value="32 256"
sudo -u www-data php $NEXTCLOUD_DIR/occ config:app:set previewgenerator widthSizes  --value="256 384"
sudo -u www-data php $NEXTCLOUD_DIR/occ config:app:set previewgenerator heightSizes --value="256"
sudo -u www-data php $NEXTCLOUD_DIR/occ config:system:set preview_max_x --value 2048
sudo -u www-data php $NEXTCLOUD_DIR/occ config:system:set preview_max_y --value 2048
sudo -u www-data php $NEXTCLOUD_DIR/occ config:system:set jpeg_quality --value 60
sudo -u www-data php $NEXTCLOUD_DIR/occ config:app:set preview jpeg_quality --value="60"
(sudo crontab -u www-data -l; echo "*/15 * * * * sudo -u www-data php $NEXTCLOUD_DIR/occ preview:pre-generate -q" ) | sudo crontab -u www-data -

# Update config.php to get prettier URLs
sudo sed -i "s/'overwrite.cli.url' => 'http:\/\/localhost',/'overwrite.cli.url' => 'https:\/\/$DOMAIN_NAME\/nextcloud',/g" $NEXTCLOUD_DIR/config/config.php
sudo sed -i "/);/i \ \ 'htaccess.RewriteBase' => '\/nextcloud'," $NEXTCLOUD_DIR/config/config.php

# Update .htaccess file after changing config.php
sudo -u www-data php $NEXTCLOUD_DIR/occ maintenance:update:htaccess

# Add convenient occ alias to bashrc
echo "
alias occ='sudo -u www-data php $NEXTCLOUD_DIR/occ'" | sudo -u admin tee -a $ADMIN_HOME/.bashrc
