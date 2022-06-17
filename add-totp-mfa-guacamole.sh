#!/bin/bash
#########################################################################
# Add TOTP (MFA) support to Guacamole  
# For Ubuntu 20.04.4 / Debian / Raspian
# David Harrop 
# April 2022
######################################################################### 
clear
cp extensions/guacamole-auth-totp-1.4.0.jar /etc/guacamole/extensions
chmod 664 /etc/guacamole/extensions/guacamole-auth-totp-1.4.0.jar
systemctl restart tomcat9

echo "Done."
