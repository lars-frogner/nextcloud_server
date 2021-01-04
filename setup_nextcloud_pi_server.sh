#!/bin/bash
set -e

# Install Raspbian Lite on SD card using Raspberry Pi Imager
# Add empty file named `ssh` in boot directory to enable ssh
# host raspberrypi | sed -n "s/^.*has address \([0-9\.]*\).*$/\1/p" # Obtain Pi IP address
# Go to router settings and forward ports 22 (SSH), [80 (HTTP), ] 443 (HTTPS) to Pi IP address
# rsync -avP nextcloud_server pi@raspberrypi:~/ # Copy setup code to Pi
# ssh pi@raspberrypi # ssh to Pi over ethernet, password is raspberry
# (optional for wifi) sudo raspi-config # -> 1 -> S1 to connect to wifi, then reboot
# (optional for wifi) ssh pi@raspberrypi.local # ssh to Pi over wifi, password is raspberry
# ./nextcloud_server/setup_nextcloud_server.sh # Run this script

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

source ./setup_users.sh $PASSWORD # Exports $ADMIN_HOME

./setup_network.sh

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

sudo reboot
