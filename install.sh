#!/bin/bash
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/tmp/install.log 2>&1
# Everything below will go to the file '/tmp/install.log':

ROOTDBPASSWD="$(date +%s | sha256sum | base64 | head -c 32 ; echo)"

motdwarn="#!/bin/sh

echo \"INSTALLATION HAS NOT YET FINISHED. LET IT BE.\""
echo "$motdwarn" > '/etc/update-motd.d/99-install-not-finished'
chmod +x /etc/update-motd.d/99-install-not-finished

# Set the Server Timezone to CST
echo "America/Montreal" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata

# Update basic image
apt-get update
apt-get -y upgrade

# Install Nginx
apt-get install -y nginx

# Install PHP5-FPM
apt-get install -y php5-fpm

# Install MySQL Server in a Non-Interactive mode. Default root password will be "root"
echo "mysql-server mysql-server/root_password password $ROOTDBPASSWD" | sudo debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $ROOTDBPASSWD" | sudo debconf-set-selections
apt-get -y install mysql-server

# Setup required database structure
mysql_install_db

# MySQL Secure Installation as defined via: mysql_secure_installation
mysql -uroot -p$ROOTDBPASSWD -e "DROP DATABASE test"
mysql -uroot -p$ROOTDBPASSWD -e "DELETE FROM mysql.user WHERE User='root' AND NOT IN ('localhost', '127.0.0.1', '::1')"
mysql -uroot -p$ROOTDBPASSWD -e "DELETE FROM mysql.user WHERE User=''"
mysql -uroot -p$ROOTDBPASSWD -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'"
mysql -uroot -p$ROOTDBPASSWD -e "FLUSH PRIVILEGES"

# Install other Requirements
apt-get -y install php5-mysql php5-cli php5-gd curl git npm ruby
ln -s /usr/bin/nodejs /usr/bin/node
gem install sass

# Create project folders
mkdir -p /www/sites/waq2016-api /www/conf/waq2016-api /www/logs/waq2016-api
mkdir -p /www/sites/waq2016-web /www/conf/waq2016-web /www/logs/waq2016-web

# Create nginx cache folder
mkdir /usr/share/nginx/cache

# Download nginx confs
wget --no-check-certificate -O /www/conf/waq2016-api/nginx.conf https://raw.githubusercontent.com/webaquebec/webaquebec2016-api/master/conf/nginx.conf
wget --no-check-certificate -O /www/conf/waq2016-web/nginx.conf https://raw.githubusercontent.com/webaquebec/webaquebec2016-web/master/conf/nginx.conf

# Remove default and put WAQ conf
unlink /etc/nginx/sites-enabled/default
ln -s /www/conf/waq2016-api/nginx.conf /etc/nginx/sites-enabled/98-waq201api
ln -s /www/conf/waq2016-web/nginx.conf /etc/nginx/sites-enabled/99-waq2016-web

rm /etc/update-motd.d/99-install-not-finished

wget --no-check-certificate -O /tmp/start.sh https://raw.githubusercontent.com/webaquebec/webaquebec2016-scripts/master/start.sh
chmod +x /tmp/start.sh

echo "$ROOTDBPASSWD" > '/www/conf/waq2016-api/ROOTDBPASSWD'
echo "Install has been completed."
echo "You can run /tmp/start.sh to install base project if not using deploys."
echo "Root MYSQL password has been written to /www/conf/waq2016-api/ROOTDBPASSWD."
echo "Please change it and delete this file after running start script."
