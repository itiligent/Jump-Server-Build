## Build A Guacamole Jump Server On Ubuntu Or Raspian ##

To install Guacamole 1.40 with an incorporated Nginx reverse proxy front end:

	sudo ./install-guacamole1.4.0-and-nginx.sh 
	
	This script builds an instance of Guacamole 1.40 bound to 127.0.01 and with options for DUO & TOTP MFA. A server hostname and Nginx site name is set before an instance of Nginx is installed and linked with Gucamole on Nginx port 80. All Nginx tweaks for enabling client IP adddress logging passthough and large file transfers are added.   The script also sets up NTP and UFW allowing incoming TCP 80/443/22 plus default allow all outgoing.
        
Adding Authentication extensions or branding after install:
	
	Choose your appropiate extension file and download for copy to a local ~/extensions directroy. 
	Duo: 
	TOTP:
	LDAP:
	Branding:
	
	Now run either of the the appropriate auth extenstion install script
	sudo ./add-duo-mfa-guacamole.sh
	sudo ./add-ldap-auth-guacamole.sh
	sudo ./add-totp-mfa-guacamole.sh
	sudo ./branding.jar (open this file with 7zip and modify login page visuals before running this)
	
	
Other server build tasks

	sudo ./create-putty-ssh-keys.sh
	Look to the text output of this script for further custom directions
	
	sudo ./disable-ssh-password-auth.sh
	After testing SSH keys are working, disable SSH password auth.


