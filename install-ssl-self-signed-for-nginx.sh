#!/bin/bash
###################################################################################
# Create self signed SSL certificates for Guacamole Nginx reverse proxy
# For Ubuntu 20.04.4 / Debian / Raspian
# David Harrop 
# June 2022
#####################################################################################
clear

echo
cat <<EOF | sudo tee -a extfile.cnf
[req]
distinguished_name  = req_distinguished_name
x509_extensions     = v3_req
prompt              = no
string_mask         = utf8only
 
[req_distinguished_name]
C                   = AU
ST                  = VICTORIA
L                   = Melbourne
O                   = Pax8
OU                  = Academy
CN                  = test.lan
 
[v3_req]
keyUsage            = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage    = serverAuth, clientAuth, codeSigning, emailProtection
subjectAltName      = @alt_names
 
[alt_names]
DNS.1               = name.your-domain.com
DNS.2               = www.your-domain.com
DNS.3               = another-domain.com

IP.1                = 10.10.10.1

EOF

${clear}
echo
echo -e "\e[1;33mSSL certificate config parameters are shown above."
echo -e "Ctrl+Z top stop this script & nano install-ssl-self-signed-for-nginx.sh to edit."
echo

####################################################################################
# Color variables
red='\033[1;31m'
green='\033[1;32m'
yellow='\033[1;33m'
blue='\033[1;34m'
magenta='\033[1;35m'
cyan='\033[1;36m'
purple='\033[1;35m'  
clear='\033[0m'

#Set default certificate file destinations. These can be adapted for any other SSL application.
DIR_SSL_CERT="/etc/nginx/ssl/cert"
DIR_SSL_KEY="/etc/nginx/ssl/private"

#Assign certificate parameter variables
SSLNAME=$1
SSLDAYS=$2

if [ -z $1 ]; then
  printf "Enter SSL Certificate name (the same reverse proxy DNS name given in the setup script:"
  read SSLNAME
fi
echo
if [ -z $2 ]; then
  printf "How many days will the new certificate be valid:"
  read SSLDAYS
fi

if [[ $SSLDAYS == "" ]]; then
  $SSLDAYS = 3650
fi
echo
while true
do
	echo -e "${GREEN}**Proxy site names are found in /etc/nginx/sites-enabled/**"
    read -p "Enter the name of your existing Nginx proxy site: " website
    echo && break
    echo
done


echo "Creating a new Certificate ..."
openssl req -x509 -nodes -newkey rsa:2048 -keyout $SSLNAME.key -out $SSLNAME.crt -days $SSLDAYS -config extfile.cnf 

# Make directory to place SSL Certificate if it doesn't exist
if [[ ! -d $DIR_SSL_KEY ]]; then
  sudo mkdir -p $DIR_SSL_KEY
fi

if [[ ! -d $DIR_SSL_CERT ]]; then
  sudo mkdir -p $DIR_SSL_CERT
fi

# Place SSL Certificate within defined path
sudo cp $SSLNAME.key $DIR_SSL_KEY/$SSLNAME.key
sudo cp $SSLNAME.crt $DIR_SSL_CERT/$SSLNAME.crt

#create a PFX formatted key for easier import to Windows hosts
sudo openssl pkcs12 -export -out $SSLNAME.pfx -inkey $SSLNAME.key -in $SSLNAME.crt -password pass:1234
sudo chmod 0774 $SSLNAME.pfx
sudo cp $SSLNAME.pfx ~/$SSLNAME.pfx

#Assists with displaying "$" and quotes in Bash output correctly
showastext1='$mypwd'
showastext2='"Cert:\LocalMachine\Root"'
showastext3='$host'
showastext4='$host'
showastext41='$request_uri'
showastext5='$proxy_add_x_forwarded_for'
showastext6='$http_upgrade'
showastext7='$http_connection'
showastext8='\'

echo
echo
# Print custom output for the various Nginx configs
#printf "${blue}+---------------------------------------------------------------------------------------------------------------------------
#+ NGINX SELF SIGNED SSL CONFIG (NO AUTO HTTP REDIRECT) 
#+
#+ Copy the below content and paste into a linux shell
#+ then restart NGINX with ${cyan}sudo systemctl restart nginx${blue}
#+---------------------------------------------------------------------------------------------------------------------------\n
#cat <<EOF | sudo tee /etc/nginx/sites-enabled/$website
#server {
#    listen 80 default_server;
#    root /var/www/html;
#    index index.html index.htm index.nginx-debian.html;
#    server_name $SSLNAME;
#
#    location / {
#        proxy_pass http://localhost:8080/guacamole/;
#        proxy_buffering off;
#        proxy_http_version 1.1;
#        proxy_set_header X-Forwarded-For $showastext8$showastext5;
#        proxy_set_header Upgrade $showastext8$showastext6;
#        proxy_set_header Connection $showastext8$showastext7;
#        access_log off;
#    }
#    listen 443 ssl;
#    ssl_certificate      $DIR_SSL_CERT/$SSLNAME.crt;
#    ssl_certificate_key  $DIR_SSL_KEY/$SSLNAME.key;
#    ssl_session_cache shared:SSL:1m;
#    ssl_session_timeout  5m;
#}
#EOF
#\n${clear}"

printf "${green}+---------------------------------------------------------------------------------------------------------------------------
+ NGINX SELF SIGNED SSL CONFIG (WITH AUTO HTTP REDIRECT)
+
+ Copy the below content and paste into a linux shell
+ then restart NGINX with ${cyan}sudo systemctl restart nginx${green}
+---------------------------------------------------------------------------------------------------------------------------\n
cat <<EOF | sudo tee /etc/nginx/sites-enabled/$website
server {
    #listen 80 default_server;
    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;
    server_name $SSLNAME;
    location / {
        proxy_pass http://localhost:8080/guacamole/;
        proxy_buffering off;
        proxy_http_version 1.1;
        proxy_set_header X-Forwarded-For $showastext8$showastext5;
        proxy_set_header Upgrade $showastext8$showastext6;
        proxy_set_header Connection $showastext8$showastext7;
        access_log off;
    }
    listen 443 ssl;
    ssl_certificate      $DIR_SSL_CERT/$SSLNAME.crt;
    ssl_certificate_key  $DIR_SSL_KEY/$SSLNAME.key;
    ssl_session_cache shared:SSL:1m;
    ssl_session_timeout  5m;
}

server {
    if ($showastext8$showastext3 = $SSLNAME) {
        return 301 https://$showastext8$showastext4$showastext8$showastext41;
    }
    listen 80 default_server;
    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;
    server_name $SSLNAME;
    location / {
        proxy_pass http://localhost:8080/guacamole/;
        proxy_buffering off;
        proxy_http_version 1.1;
        proxy_set_header X-Forwarded-For $showastext8$showastext5;
        proxy_set_header Upgrade $showastext8$showastext6;
        proxy_set_header Connection $showastext8$showastext7;
        access_log off;
    }
}
EOF

${clear}"

printf "${red}+---------------------------------------------------------------------------------------------------------------------------
+ WINDOWS CLIENT SELF SIGNED SSL CONFIG 
+
+ Look in your Linux home directory for the Windows friendly version of the new certificate ${cyan}$SSLNAME.pfx${red}
+ Import the PFX file into Windows with the following Powershell commands (as administrator)
+---------------------------------------------------------------------------------------------------------------------------\n${clear}"
echo
echo -e "\e[1;31m${showastext1} = ConvertTo-SecureString -String "1234" -Force -AsPlainText \e[0m"
echo -e "\e[1;31mImport-pfxCertificate -FilePath $SSLNAME.pfx -Password "${showastext1}" -CertStoreLocation "${showastext2}" \e[0m"
echo -e "\e[1;31mClear your browser cache and restart your browser to test"
echo

printf "${purple}+---------------------------------------------------------------------------------------------------------------------------
+ LINUX CLIENT SELF SIGNED SSL CONFIG
+
+ Look to your Linux home directory for a copy of the native OpenSSL certificate ${cyan}$SSLNAME.crt${purple}
+ Import the CRT file into the Linux certificate store with the below command
+---------------------------------------------------------------------------------------------------------------------------\n${clear}"
echo
echo -e "\e[1;35mcertutil -d sql:$HOME/.pki/nssdb -A -t "CT,C,c" -n $SSLNAME -i $SSLNAME.crt"${clear}
echo -e "\e[1;35m#if you don't have certutil installed ${cyan}apt-get install libnss3-tools"${clear} 
echo
rm extfile.cnf


#Nginx somtimes needs a double bounce to avoid a restart
sudo systemctl restart tomcat9
sudo systemctl restart guacd
sudo systemctl restart nginx
sleep 2
sudo systemctl restart tomcat9
sudo systemctl restart guacd
sudo systemctl restart nginx



