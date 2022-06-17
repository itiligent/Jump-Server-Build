#!/bin/bash
#########################################################################
# Guac web install downloader script  
# For Ubuntu 20.04.4 / Debian / Raspian
# David Harrop 
# June 2022
######################################################################### 



## Auth extensions
wget https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/add-duo-mfa-guacamole.sh
wget https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/guacamole-auth-duo-1.4.0.jar
wget https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/add-totp-mfa-guacamole.sh
wget https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/guacamole-auth-totp-1.4.0.jar
wget https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/add-ldap-auth-guacamole.sh
wget https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/guacamole-auth-ldap-1.4.0.jar

##branding extention
wget https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/branding.jar

##SSH configs
wget https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/create-putty-ssh-keys.sh
wget https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/disable-ssh-password-auth.sh

##SSL
wget https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/install-ssl-letsencrypt-for-nginx.sh
wget https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/install-ssl-self-signed-for-nginx.sh

##Config info
wget https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/Guac-Completion-Tasks.doc

chmod +x *.sh

wget https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/install-guacamole1.4.0-and-nginx.sh -v -O install-guacamole1.4.0-and-nginx.sh && ./install-guacamole1.4.0-and-nginx.sh


