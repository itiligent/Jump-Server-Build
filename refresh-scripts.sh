#!/bin/bash
#########################################################################
# Guac script updated for test & dev. Refresh the local scripts   
# For Ubuntu 20.04.4 / Debian / Raspian
# David Harrop 
# June 2022
######################################################################### 

# Download setup components

	# Manual config scripts
		wget -O add-duo-mfa-guacamole.sh https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/add-duo-mfa-guacamole.sh 
		wget -O add-totp-mfa-guacamole.sh https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/add-totp-mfa-guacamole.sh 
		wget -O add-ldap-auth-guacamole.sh https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/add-ldap-auth-guacamole.sh 

	# SSH config scripts
		wget -O create-putty-ssh-keys.sh https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/create-putty-ssh-keys.sh &> 
		wget -O disable-ssh-password-auth.sh https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/disable-ssh-password-auth.sh 
		
	# SSL config scripts
		wget -O install-ssl-letsencrypt-nginx.sh https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/install-ssl-letsencrypt-nginx.sh 
		wget -O install-ssl-self-signed-nginx.sh https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/install-ssl-self-signed-nginx.sh 

	# Auth extensions
		mkdir extensions
		wget -O extensions/guacamole-auth-duo-1.4.0.jar https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/guacamole-auth-duo-1.4.0.jar 
		wget -O extensions/guacamole-auth-totp-1.4.0.jar https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/guacamole-auth-totp-1.4.0.jar 
		wget -O extensions/guacamole-auth-ldap-1.4.0.jar https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/guacamole-auth-ldap-1.4.0.jar 

	# Branding extension
		wget -O extensions/branding.jar https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/branding.jar 


# Download final config instructions 
		wget -O Guac-Completion-Tasks.doc https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/Guac-Completion-Tasks.doc 

# Download main installer script
		wget -O install-guacamole1.4.0-and-nginx.sh https://raw.githubusercontent.com/itiligent/Guacamole-With-Nginx-Build/main/install-guacamole1.4.0-and-nginx.sh

# Make all scripts everything executable
chmod +x *.sh


