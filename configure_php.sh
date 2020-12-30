#!/bin/bash
set -e

UPLOAD_FILE_LIMIT=10G
MEMORY_LIMIT=1G

set -x

# Increase max upload limit
sudo sed -i "s/post_max_size = 8M/post_max_size = $UPLOAD_FILE_LIMIT/g" /etc/php/7.3/apache2/php.ini
sudo sed -i "s/upload_max_filesize = 2M/upload_max_filesize = $UPLOAD_FILE_LIMIT/g" /etc/php/7.3/apache2/php.ini
sudo sed -i "s/memory_limit = 128M/memory_limit = $MEMORY_LIMIT/g" /etc/php/7.3/apache2/php.ini
sudo service apache2 restart
