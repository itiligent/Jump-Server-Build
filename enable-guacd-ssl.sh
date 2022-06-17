#!/bin/bash
################################################################
## Harden Guacd <-> Guac client traffic in SSL wrapper
## David Harrop
## April 2022
################################################################ 

#Create the special directory for guacd ssl certfifacte and key.
sudo mkdir /etc/guacamole/ssl

#Create the self signining request, certificate & key
sudo openssl req -x509 -nodes -days 36500 -newkey rsa:2048 -keyout /etc/guacamole/ssl/guacd.key -out /etc/guacamole/ssl/guacd.crt

#Point Gaucamole config file to certificate any key
sudo cat <<EOF | sudo tee /etc/guacamole/guacd.conf
[server]
bind_host = 127.0.0.1
bind_port = 4822
[ssl]
server_certificate = /etc/guacamole/ssl/guacd.crt
server_key = /etc/guacamole/ssl/guacd.key
EOF

#Enable SSL backend
sudo cat <<EOF | sudo tee -a /etc/guacamole/guacamole.properties
guacd-ssl: true
EOF

#fix required permissions as guacd only runs as daemon 
sudo chown daemon:daemon /etc/guacamole/ssl
sudo chown daemon:daemon /etc/guacamole/ssl/guacd.key
sudo chown daemon:daemon /etc/guacamole/ssl/guacd.crt
sudo chmod 644 /etc/guacamole/ssl/guacd.crt
sudo chmod 644 /etc/guacamole/ssl/guacd.key

#Add the new certificate into the Java Runtime certificate store and set JRE to trust it. 
cd /etc/guacamole/ssl
sudo keytool -importcert -alias guacd -keystore /usr/lib/jvm/java-11-openjdk-amd64/lib/security/cacerts -file guacd.crt

