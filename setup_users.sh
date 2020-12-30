
#!/bin/bash
set -e

PASSWORD=${1?"Usage: $0 <password>"}

set -v

# Set pi user password
echo pi:$PASSWORD | sudo chpasswd

# Add admin user
sudo useradd -m -G sudo admin

# Set admin user password
echo admin:$PASSWORD | sudo chpasswd

export ADMIN_HOME=/home/admin

# Enable convenient ls aliases
sudo -u admin sed -i "s/#alias ll='ls -l'/alias ll='ls -l'/g" $ADMIN_HOME/.bashrc
sudo -u admin sed -i "s/#alias la='ls -A'/alias la='ls -A'/g" $ADMIN_HOME/.bashrc
sudo -u admin sed -i "s/#alias l='ls -CF'/alias l='ls -CF'/g" $ADMIN_HOME/.bashrc

# Enable arrow up/down history search
sudo -u admin cp /etc/inputrc $ADMIN_HOME/.inputrc
sudo -u admin sed -i 's/# "\\e\[B": history-search-forward/"\\e[B": history-search-forward/g' $ADMIN_HOME/.inputrc
sudo -u admin sed -i 's/# "\\e\[A": history-search-backward/"\\e[A": history-search-backward/g' $ADMIN_HOME/.inputrc
