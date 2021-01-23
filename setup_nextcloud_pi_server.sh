#!/bin/bash
set -e

# Install Raspbian Lite on SD card using Raspberry Pi Imager
# Add empty file named `ssh` in boot directory to enable ssh
# rsync -avP nextcloud_server pi@raspberrypi:~/ # Copy setup code to Pi, password is raspberry
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

SCRIPT_DIR=$(dirname $(readlink -f "$0"))

source $SCRIPT_DIR/setup_users.sh $PASSWORD # Exports $ADMIN_HOME

source $SCRIPT_DIR/setup_network.sh # Exports $HOST_IP

$SCRIPT_DIR/install_lamp.sh

source $SCRIPT_DIR/install_nextcloud.sh # Exports $NEXTCLOUD_ROOT

$SCRIPT_DIR/setup_mysql.sh $PASSWORD

$SCRIPT_DIR/configure_apache.sh

$SCRIPT_DIR/configure_php.sh

source $SCRIPT_DIR/install_noip_duc.sh # Exports $DOMAIN_NAME

SETUP_HTTPS_CERTIFICATE=false
if [[ "$SETUP_HTTPS_CERTIFICATE" = true ]]; then
    echo "Go to router settings and forward ports 22 (SSH), 80 (HTTP) and 443 (HTTPS) to IP $HOST_IP"
    read -p "Press ENTER to continue"
    $SCRIPT_DIR/install_certbot.sh
    echo "You can now close port 80"
fi

source $SCRIPT_DIR/setup_storage.sh # Exports $PRIMARY_STORAGE

$SCRIPT_DIR/setup_nextcloud.sh $PASSWORD

set +v

echo "Go to $DOMAIN_NAME/nextcloud in browser and login as admin"

sudo reboot
