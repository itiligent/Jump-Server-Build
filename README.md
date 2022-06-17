## Build a Guacamole jump server on Ubuntu or Raspian ##

To install Guacamole 1.40 with an incorporated Nginx reverse proxy front end:

	sudo ./install-guacamole1.4.0-and-nginx.sh 
	
	This script builds an instance of Guacamole 1.40 bound to 127.0.01 and with options for DUO & TOTP MFA. A server hostname and Nginx site name is set before an instance of Nginx is installed and linked with Gucamole on Nginx port 80. All Nginx tweaks for enabling client IP adddress logging passthough and large file transfers are added.   The script also sets up NTP and UFW allowing incoming TCP 80/443/22 plus default allow all outgoing.
        
Config options:
