#!/bin/bash
set -e
set -x

CONNECTION=$(ip route get 8.8.8.8 | grep -Po 'dev \K\w+' | grep -qFf - /proc/net/wireless && echo wlan0 || echo eth0)
HOST_IP=$(host raspberrypi | sed -n "s/^.*has address \([0-9\.]*\).*$/\1/p")
ROUTER_IP=$(ip r | grep default | sed -n "s/^default via \([0-9\.]*\).*$/\1/p")
DNS_IP=$(sudo sed -n "s/^nameserver \([0-9\.]*\).*$/\1/p" /etc/resolv.conf | head -n 1)

# Check if dhcpcd service is running
if [[ -z $(systemctl | grep dhcpcd.service) ]]
then
    # If not, start it
    sudo service dhcpcd start
    sudo systemctl enable dhcpcd
fi

# Set static IP to current IP in dhcpcd.conf
echo "
interface $CONNECTION
static ip_address=$HOST_IP/24
static routers=$ROUTER_IP
static domain_name_servers=$DNS_IP" | sudo tee -a /etc/dhcpcd.conf
