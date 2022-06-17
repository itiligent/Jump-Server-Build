#!/bin/bash
###################################################################################
# Add Nginx reverse proxy with Gaucamole on port 80
# For Ubuntu 20.04.4 / Debian / Raspian
# David Harrop (with multiple external resources)
# April 2022
################################################################################### 
# Get domain or site name 
while true
do
    read -p "Enter the name of your local site: " website
    echo
    read -p "Confirm the name of your local site: " website2
    echo
    [ "$website" = "$website2" ] && break
    echo "Domains don't match. Please try again."
    echo
done

# Update package lists
apt-get update
# Upgrade existing packages
apt-get upgrade -y
# Install nginx
apt-get install nginx -y

guacamoleurl=http://localhost:8080/guacamole/

# Configure /etc/nginx/sites-available/(website name)
cat >/etc/nginx/sites-available/$website <<EOL
server {
    listen 80 default_server;
    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;
    server_name $website;
    location / {
        proxy_pass $guacamoleurl;
        proxy_buffering off;
        proxy_http_version 1.1;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$http_connection;
        access_log off;
    }
}
EOL

# symlink from sites-available to sites-enabled
ln -s /etc/nginx/sites-available/$website /etc/nginx/sites-enabled/
# make sure default is unlinked
unlink /etc/nginx/sites-enabled/default

#Nginx somtimes needs a double bounce to avoid a restart
sudo systemctl start nginx
sudo systemctl restart tomcat9
sudo systemctl restart guacd
sudo systemctl restart nginx
sleep 2
sudo systemctl restart nginx
sudo systemctl restart tomcat9
sudo systemctl restart guacd
sudo systemctl restart nginx

#Update firewall rules to force Guacamole access through the reverse proxy
sudo ufw default allow outgoing
sudo ufw default deny incoming
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw deny 8080/tcp
echo "y" | sudo ufw enable
