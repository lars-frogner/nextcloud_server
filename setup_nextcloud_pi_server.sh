#!/bin/bash
set -e

# Install Raspbian Lite on SD card using Raspberry Pi Imager
# Add empty file named `ssh` in boot directory to enable ssh
# ping raspberrypi # Get IP for ssh login
# ssh root@<ip> # ssh to Pi, password is raspberry

read -p "[host: $(hostname)] Continue? " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi

stty -echo
printf "Password: "
read PASSWORD
stty echo
printf "\n"

set -v

./setup_users.sh $PASSWORD # Exports $ADMIN_HOME

./install_lamp.sh

source ./install_nextcloud.sh # Exports $NEXTCLOUD_ROOT

./setup_mysql.sh $PASSWORD

./configure_apache.sh

./configure_php.sh

source ./install_noip_duc.sh # Exports $DOMAIN_NAME

./install_certbot.sh

source ./setup_storage.sh # Exports $PRIMARY_STORAGE

./setup_nextcloud.sh $PASSWORD

set +v

echo "Go to $DOMAIN_NAME/nextcloud in browser and login as admin"
