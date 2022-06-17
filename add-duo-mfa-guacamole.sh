#!/bin/bash
#########################################################################
# Add Duo MFA support to Guacamole  
# For Ubuntu 20.04.4 / Debian / Raspian
# David Harrop 
# April 2022
######################################################################### 
clear
cp guacamole-auth-duo-1.4.0.jar /etc/guacamole/extensions
chmod 664 /etc/guacamole/extensions/guacamole-auth-duo-1.4.0.jar
echo "# duo-integration-key: " >> /etc/guacamole/guacamole.properties
echo "# duo-secret-key: " >> /etc/guacamole/guacamole.properties
echo "# duo-api-hostname: " >> /etc/guacamole/guacamole.properties
echo "# duo-application-key: " >> /etc/guacamole/guacamole.properties

systemctl restart tomcat9

echo "Done. You must now set up your online Duo account with a new 'Web SDK' application."
echo 
echo "Copy the approriate API settings from your Duo account into /etc/guacamole/guacamole.properties in the below format."
echo "Be VERY careful to avoid extra spaces or characters when pasting!"
echo 
echo "duo-integration-key: ??????????"
echo "duo-api-hostname: ??????????"
echo "duo-secret-key: ??????????"
echo "duo-application-key: (this is locally created - run 'pwgen 40 1' to manually generate this 40 char random value)"
echo
echo "Then restart Guacamole with sudo systemctl restart tomcat9"

