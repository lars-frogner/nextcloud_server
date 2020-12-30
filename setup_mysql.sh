#!/bin/bash
set -e

PASSWORD=${1?"Usage: $0 <password>"}

set -v

# Start MySQL
sudo /etc/init.d/mysql start

# Create MariaDB/MySQL user and database for nextcloud
echo "CREATE USER 'admin'@'localhost' IDENTIFIED BY '$PASSWORD';
CREATE DATABASE IF NOT EXISTS nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
GRANT ALL PRIVILEGES ON nextcloud.* TO 'admin'@'localhost';
FLUSH PRIVILEGES;" > create_nextcloud_db
sudo mysql --password= < create_nextcloud_db
rm create_nextcloud_db
