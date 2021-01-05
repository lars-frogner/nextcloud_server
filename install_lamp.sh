#!/bin/bash
set -e
set -x

sudo apt update

# Install Apache
sudo apt -y install apache2

# Install MariaDB
sudo apt -y install mariadb-server

# Install PHP
sudo apt -y install libapache2-mod-php7.3 php7.3-gd php7.3-mysql php7.3-curl php7.3-mbstring php7.3-intl php7.3-gmp php7.3-bcmath php7.3-xml php7.3-zip php7.3-bz2 php-imagick

# Restart Apache
sudo service apache2 restart

set +x
