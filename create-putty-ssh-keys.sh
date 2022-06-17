#!/bin/bash
###################################################################################
# Create ssh keys for remote putty ssh access  
# For Ubuntu / Debian / Raspian
# David Harrop 
# June 2022
# DO NOT RUN THIS SCRIPT WITH SUDO!!
# LET THE SCRIPT ITSELF PROMPT FOR SUDO AFTER RUNNING IT
# (SSH KEYS Cant be copied to ~/ with sudo invoked at runtime) 
###################################################################################
clear
#make sure putty-tools is available

mkdir ~/.ssh
touch ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 644 ~/.ssh/authorized_keys

#SUDO IS ONLY NEEDED HERE
sudo apt update 
sudo apt install putty-tools

while true
do
echo
echo  
   read -p "Enter the Linux hostname (to append to new SSH key names): " name
    echo
    echo
	break
done

#declare some starting variables
h=$name
red='\033[1;31m'
green='\033[1;32m'
yellow='\033[1;33m'
clear='\033[0m'
u="$USER"




#Change to the correct hostname (A live system name is needed for tracking SSH keys)
#sudo hostname $name
#echo
#echo -e "\e[1;33mChanging Linux hostname to match new SSH keys"
#echo
#echo -e "\e[1;33mSystem name changed to $h, you may need to logoff or reboot to see this change" 
#echo 
echo -e "\e[1;33mCreating SSH keys for $u@$h"
echo
echo -e "\e[1;31mWhen promted, DO NOT add a password. Hit Enter twice to finish"${clear}

puttygen -t rsa -b 2048 -C "$u@$h" -o ~/$h-sshkey-priv-$u.ppk

puttygen -L ~/$h-sshkey-priv-$u.ppk -o ~/$h-sshkey-pub-$u.txt

cat ~/$h-sshkey-pub-$u.txt >> ~/.ssh/authorized_keys 

# Print custom output for the the private key
printf "${red}+---------------------------------------------------------------------------------------------------------------------------
+ PUTTY PRIVATE SSH KEY  
+
+ Save the below private key content as${yellow} private-key-$u@$h.ppk${red} for use with Putty client connections
+ 
+ This file output has also been saved to your home directory. Once copied, you should DELETE ALL LOCAL PRIVATE KEY files.
+---------------------------------------------------------------------------------------------------------------------------\n${clear}"
cat ~/$h-sshkey-priv-$u.ppk
printf "${red}+---------------------------------------------------------------------------------------------------------------------------\n\n${clear}"

# Print custom output for the public key
printf "${green}+---------------------------------------------------------------------------------------------------------------------------
+ PUTTY PUBLIC KEY 
+
+ Save the below private key content as ${yellow}public-key-$u@$h.txt${green} as a backup.
+ 
+ This file output has also been automatically imported into the ~/.ssh/authorised keys file and saved to your home directory.
+ SSH connections will now authenitcate using the matching Private Key  
+---------------------------------------------------------------------------------------------------------------------------\n${clear}"
cat ~/$h-sshkey-pub-$u.txt
printf "${green}+---------------------------------------------------------------------------------------------------------------------------\n\n${clear}"



