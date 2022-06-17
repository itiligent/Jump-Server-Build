#!/bin/bash
#########################################################################
# Guac web install downloader script  
# For Ubuntu 20.04.4 / Debian / Raspian
# David Harrop 
# June 2022
######################################################################### 

## Auth extensions
wget -O add-duo-mfa-guacamole.sh https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/add-duo-mfa-guacamole.sh
wget -O guacamole-auth-duo-1.4.0.jar https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/guacamole-auth-duo-1.4.0.jar
wget -O add-totp-mfa-guacamole.sh https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/add-totp-mfa-guacamole.sh
wget -O guacamole-auth-totp-1.4.0.jar https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/guacamole-auth-totp-1.4.0.jar
wget -O add-ldap-auth-guacamole.sh https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/add-ldap-auth-guacamole.sh
wget -O guacamole-auth-ldap-1.4.0.jar https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/guacamole-auth-ldap-1.4.0.jar

##branding extention
wget -O branding.jar https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/branding.jar

##SSH configs
wget -O create-putty-ssh-keys.sh https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/create-putty-ssh-keys.sh
wget -O  disable-ssh-password-auth.sh https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/disable-ssh-password-auth.sh

##SSL
wget -O install-ssl-letsencrypt-for-nginx.sh https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/install-ssl-letsencrypt-for-nginx.sh
wget -O  install-ssl-self-signed-for-nginx.sh https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/install-ssl-self-signed-for-nginx.sh

##Config info
wget -O  Guac-Completion-Tasks.doc https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/Guac-Completion-Tasks.doc

#Main installer script
wget -O install-guacamole1.4.0-and-nginx.sh https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/install-guacamole1.4.0-and-nginx.sh

chmod +x *.sh

sudo ./install-guacamole1.4.0-and-nginx.sh



