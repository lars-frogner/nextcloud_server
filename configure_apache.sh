#!/bin/bash
set -e
set -x

# Create nextcloud config file for Apache
echo "Alias /nextcloud \"/var/www/nextcloud/\"

<Directory /var/www/nextcloud/>
  Require all granted
  AllowOverride All
  Options FollowSymLinks MultiViews

  <IfModule mod_dav.c>
    Dav off
  </IfModule>

</Directory>" | sudo tee /etc/apache2/sites-available/nextcloud.conf

# Enable nextcloud
sudo a2ensite nextcloud.conf

# Enable recommended modules
sudo a2enmod rewrite
sudo a2enmod headers

# Reload configuration
sudo systemctl reload apache2
