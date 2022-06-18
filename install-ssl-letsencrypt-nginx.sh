#!/bin/bash
###################################################################################
# Add Nginx reverse proxy & Public SSL Certificates to default Gaucamole install
# For Ubuntu 20.04.4 / Debian / Raspian
# David Harrop 
# April 2022
################################################################################### 

##@@## Colors to use for output
GREEN='\033[1;32m'
CYAN='\033[1;36m'
NC='\033[0m' # No Color
clear
# Update package lists
apt-get update
# Upgrade existing packages
apt-get upgrade -y
# Install nginx
apt-get install nginx certbot python3-certbot-nginx -y
clear

# Get existing Nginx config name 
for file in "/etc/nginx/sites-enabled"/*
do
    echo "${file##*/}" 
    proxysite="${file##*/}" 
    echo "proxysite = " > "${proxysite}" 
done

clear

# Backup existing Nginx config before we break things
sudo -H cp /etc/nginx/sites-enabled/$proxysite /home/$HOME/$proxysite.bak
echo 
echo -e "${YELLOW}Existing Nginx proxy site config backed up to ~/$proxysite.bak"
echo
echo

# Get domain name, email address and old site names for new Let's encrypt certificate
while true
do
    read -p "Enter the PUBLIC FQDN for your site: " website
    echo
    read -p "Confirm the PUBLIC FQDN for your site: " website2
    echo
    [ "$website" = "$website2" ] && break
    echo "Domains don't match. Please try again."
    echo
done
echo

while true
do
    read -p "Enter your email address: " certbotemail
    echo
    read -p "Confirm your email address: " certbotemail2
    echo
    [ "$certbotemail" = "$certbotemail2" ] && break
    echo "Email addresses don't match. Please try again."
    echo
done


# Redundant now $proxysite is in use to identify the current location of the HTTP site. Keeping it just in case of multiple sites on Nginx
while true
do
	echo -e "${GREEN}**Proxy site names are found in /etc/nginx/sites-enabled/**"
    read -p "Enter name of EXISTING Nginx proxy site to reconfigure e.g. ${proxysite}: " oldsite
	echo
	echo
	break
	echo -e "Reconfiguring $oldsite proxy website for SSL${CYAN}" 
	echo
done



guacamoleurl=http://localhost:8080/guacamole/

# Configure /etc/nginx/sites-available/(website name)
cat >/etc/nginx/sites-available/$website <<EOL
server {
    listen 80 default_server;
    #listen [::]:80 default_server;
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



#make sure default and previous HTTP sites are unlinked
unlink /etc/nginx/sites-enabled/default
unlink /etc/nginx/sites-enabled/$proxysite
# symlink from sites-available to sites-enabled
ln -s /etc/nginx/sites-available/$website /etc/nginx/sites-enabled/

# Bounce  Nginx
systemctl restart nginx

#add-apt-repository ppa:certbot/certbot -y
#apt-get update
#certbot --nginx -n -d $website --email $certbotemail --agree-tos --redirect --hsts

