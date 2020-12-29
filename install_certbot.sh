#!/bin/bash
set -e
set -x

# Install certbot
sudo apt -y install python-certbot-apache

# Grab SSL certificate from Let's Encrypt and configure Apache
sudo certbot --apache
