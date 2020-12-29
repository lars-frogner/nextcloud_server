#!/bin/bash
set -e

NOIP_ROOT=/home/pi

set -x

# Download and install No-IP Dynamic Update Client
wget https://www.noip.com/client/linux/noip-duc-linux.tar.gz -P $NOIP_ROOT/
tar -xvzf $NOIP_ROOT/noip-duc-linux.tar.gz -C $NOIP_ROOT/
rm $NOIP_ROOT/noip-duc-linux.tar.gz
cd $NOIP_ROOT/noip-2.1.9-1
sudo make
sudo make install
cd -

# Start DUC
sudo /usr/local/bin/noip2
DOMAIN_NAME=$(sudo /usr/local/bin/noip2 -S 2>&1 >/dev/null | sed -n "s/^.*host\s*\(\S*\).*$/\1/p")

# Make sure DUC service is started automatically on boot
sudo sed -i '/^exit 0.*/i /usr/local/bin/noip2' /etc/rc.local

echo $DOMAIN_NAME
