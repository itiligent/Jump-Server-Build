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
red='\033[1;31m'
green='\033[1;32m'
yellow='\033[1;33m'
clear='\033[0m'

# This script must not be run as root. Must be in the user context to create the 
# correct user keys in their correct loctions
if [ "$EUID" -ne 0 ]
  then echo -e "${green}Script started as non sudo user, all good."
	   echo -e "${green}You will be prompted to enter sudo credentials shortly..${clear}"
    else
        echo -e "${yellow}DO NOT START THIS SCRIPT AS SUDO OR ROOT."
		echo -e "${yellow}Instead, start the script as a regular user,"
		echo -e "${yellow}the script will then prompt for a sudo pw.${clear}" 
		echo
  exit
fi

mkdir ~/.ssh
touch ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 644 ~/.ssh/authorized_keys

#make sure putty-tools is available
#SUDO IS ONLY NEEDED HERE
sudo apt-get update 
sudo apt-get install putty-tools -y

sudo sed -i  '$ a PubkeyAcceptedAlgorithms=+ssh-rsa' /etc/ssh/sshd_config
sudo systemctl restart sshd



echo -e "${green}"
while true
do
echo
echo  
   read -p "Enter the Linux hostname to append to new SSH key names: " name
    echo
    echo
	break
done

clear

#declare some extra variables
h=$name
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
echo -e "\e[1;31mWhen promted, DO NOT ADD A PASSWORD. Hit Enter twice to finish"${clear}

puttygen --ppk-param version=2 -t rsa -b 2048 -C "$u@$h" -o ~/$h-sshkey-priv-$u.ppk

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



