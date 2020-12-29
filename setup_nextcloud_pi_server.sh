#!/bin/bash
set -e

# Install Raspbian Lite on SD card using Raspberry Pi Imager
# Add empty file named `ssh` in boot directory to enable ssh
# ping raspberrypi # Get IP for ssh login
# ssh pi@<ip> # ssh to Pi, password is raspberry

read -p "[host: $(hostname), user: $(whoami)] Continue? " -n 1 -r
echo    # (optional) move to a new line
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

./set_password.sh $PASSWORD

./install_lamp.sh

NEXTCLOUD_ROOT=$(./install_nextcloud.sh)

./setup_mysql.sh $PASSWORD

./configure_apache.sh

./configure_php.sh

DOMAIN_NAME=$(./install_noip_duc.sh)

./install_certbot.sh

PRIMARY_STORAGE=$(./setup_storage.sh)

./setup_nextcloud.sh $PASSWORD $NEXTCLOUD_ROOT $PRIMARY_STORAGE $DOMAIN_NAME

set +v

echo "Go to $DOMAIN_NAME/nextcloud in browser and login as admin"
