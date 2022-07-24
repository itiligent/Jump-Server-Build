#!/bin/bash
#########################################################################
# Guac web install downloader script  
# For Ubuntu 20.04.4 / Debian / Raspian
# David Harrop 
# June 2022
######################################################################### 

clear

# Download setup components

	# Manual config scripts
		wget -O add-duo-mfa-guacamole.sh https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/add-duo-mfa-guacamole.sh &> /dev/null
		wget -O add-totp-mfa-guacamole.sh https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/add-totp-mfa-guacamole.sh &> /dev/null
		wget -O add-ldap-auth-guacamole.sh https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/add-ldap-auth-guacamole.sh &> /dev/null

	# SSH config scripts
		wget -O create-putty-ssh-keys.sh https://raw.githubusercontent.com/itiligent/Linux-Stuff/main/create-putty-ssh-keys.sh &> /dev/null
		wget -O disable-ssh-password-auth.sh https://raw.githubusercontent.com/itiligent/Linux-Stuff/main/disable-ssh-password-auth.sh &> /dev/null

	# SSL config scripts
		wget -O install-ssl-letsencrypt-nginx.sh https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/install-ssl-letsencrypt-nginx.sh &> /dev/null
		wget -O install-ssl-self-signed-nginx.sh https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/install-ssl-self-signed-nginx.sh &> /dev/null

	# Auth extensions
		mkdir extensions
		wget -O extensions/guacamole-auth-duo-1.4.0.jar https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/guacamole-auth-duo-1.4.0.jar &> /dev/null
		wget -O extensions/guacamole-auth-totp-1.4.0.jar https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/guacamole-auth-totp-1.4.0.jar &> /dev/null
		wget -O extensions/guacamole-auth-ldap-1.4.0.jar https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/guacamole-auth-ldap-1.4.0.jar &> /dev/null

	# Branding extension
		wget -O extensions/branding.jar https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/branding.jar &> /dev/null


# Download final config instructions 
		wget -O Guac-Completion-Tasks.doc https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/Guac-Completion-Tasks.doc &> /dev/null

# Download main installer script
		wget -O install-guacamole1.4.0-and-nginx.sh https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/install-guacamole1.4.0-and-nginx.sh &> /dev/null

# Make all scripts everything executable
chmod +x *.sh

# Run the install script
sudo ./install-guacamole1.4.0-and-nginx.sh

# Apply the branded login page
sudo cp extensions/branding.jar /etc/guacamole/extensions &> /dev/null
sudo systemctl restart tomcat9 &> /dev/null
# dont keep a local copy if installer, its better for future updates if this script is staged from github
rm install-guacamole1.4.0-and-nginx.sh &> /dev/null
rm setup.sh &> /dev/null
