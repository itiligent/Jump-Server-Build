#!/bin/bash
#########################################################################
# Build a Guacamole jump server incorporating Nginx reverse proxy 
# For Ubuntu 20.04.4 / Debian / Raspian
# David Harrop 
# April 2022
######################################################################### 
# Something isn't working? # tail -f /var/log/messages /var/log/syslog /var/log/tomcat*/*.out /var/log/mysql/*.log

##@@## Start fresh
clear

##@@## Colors to use for output
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
RED='\033[1;31m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
PURPLE='\033[1;35m' 
NC='\033[0m' # No Color

##@@## Ask for the desired server hostname
while true
do
	echo -e "${GREEN}"
	echo  
	read -p "Confirm this jumpbox Linux HOSTNAME: " name
	echo
	echo
	break
	echo
done 

# Ask for reverse proxy site name - this needs to match with later ssl installation scripts 
while true
do
	echo   
	read -p "Enter new Nginx reverse proxy site name e.g. guacamole : " website
	echo -e "Please Note: The same proxy site name just must be used for optional SSL install scripts"
	echo 	
    break
    echo -e "${NC}"
done


##@@## Change server hostname to entered value 

sudo hostnamectl set-hostname $name
sudo sed -i '/127.0.1.1/d' /etc/hosts
echo '127.0.1.1       $name' | sudo tee -a /etc/hosts
sudo systemctl restart systemd-hostnamed



# Check if user is root or sudo
if ! [ $( id -u ) = 0 ]; then
    echo "Please run this script as sudo or root" 1>&2
    exit 1
fi

# Check to see if any old files left over
if [ "$( find . -maxdepth 1 \( -name 'guacamole-*' -o -name 'mysql-connector-java-*' \) )" != "" ]; then
    echo "Possible temp files detected. Please review 'guacamole-*' & 'mysql-connector-java-*'" 1>&2
    exit 1
fi

# Version number of Guacamole to install
# Homepage ~ https://guacamole.apache.org/releases/
GUACVERSION="1.4.0"

# Latest Version of MySQL Connector/J if manual install is required (if libmariadb-java/libmysql-java is not available via apt)
# Homepage ~ https://dev.mysql.com/downloads/connector/j/
MCJVER="8.0.27"

# Log Location
LOG="/tmp/guacamole_${GUACVERSION}_build.log"

# Initialize variable values
installTOTP=""
installDuo=""
installMySQL=""
mysqlHost=""
mysqlPort=""
mysqlRootPwd=""
guacDb=""
guacUser=""
guacPwd=""
PROMPT=""
MYSQL=""
##@@## Override if needed
#website="guacamole"

# Get script arguments for non-interactive mode
while [ "$1" != "" ]; do
    case $1 in
        # Install MySQL selection
        -i | --installmysql )
            installMySQL=true
            ;;
        -n | --nomysql )
            installMySQL=false
            ;;

        # MySQL server/root information
        -h | --mysqlhost )
            shift
            mysqlHost="$1"
            ;;
        -p | --mysqlport )
            shift
            mysqlPort="$1"
            ;;
        -r | --mysqlpwd )
            shift
            mysqlRootPwd="$1"
            ;;

        # Guac database/user information
        -db | --guacdb )
            shift
            guacDb="$1"
            ;;
        -gu | --guacuser )
            shift
            guacUser="$1"
            ;;
        -gp | --guacpwd )
            shift
            guacPwd="$1"
            ;;

        # MFA selection
        -t | --totp )
            installTOTP=true
            ;;
        -d | --duo )
            installDuo=true
            ;;
        -o | --nomfa )
            installTOTP=false
            installDuo=false
            ;;
    esac
    shift
done

if [[ -z "${installTOTP}" ]] && [[ "${installDuo}" != true ]]; then
    # Prompt the user if they would like to install TOTP MFA, default of no
    echo -e -n "${CYAN}MFA: Would you like to install TOTP (choose 'N' if you want Duo)? (y/N): ${NC}"
    read PROMPT
	echo
    if [[ ${PROMPT} =~ ^[Yy]$ ]]; then
        installTOTP=true
        installDuo=false
    else
        installTOTP=false
    fi
fi

if [[ -z "${installDuo}" ]] && [[ "${installTOTP}" != true ]]; then
    # Prompt the user if they would like to install Duo MFA, default of no
    echo -e -n "${CYAN}MFA: Would you like to install Duo (configuration values must be set after install in /etc/guacamole/guacamole.properties)? (y/N): ${NC}"
    read PROMPT
    if [[ ${PROMPT} =~ ^[Yy]$ ]]; then
        installDuo=true
        installTOTP=false
    else
        installDuo=false
    fi
fi

# We can't install TOTP and Duo at the same time...
if [[ "${installTOTP}" = true ]] && [ "${installDuo}" = true ]; then
    echo -e "${RED}MFA: The script does not support installing TOTP and Duo at the same time.${NC}" 1>&2
    exit 1
fi
echo

if [[ -z ${installMySQL} ]]; then
    # Prompt the user to see if they would like to install MySQL, default of yes
##@@## Fix Colours
	echo -e "${YELLOW}"
    echo "MySQL is required for installation, if you're using a remote MySQL Server select 'n'"
    echo -e -n "Would you like to install MySQL? (Y/n): ${NC}"
    read PROMPT
    if [[ ${PROMPT} =~ ^[Nn]$ ]]; then
        installMySQL=false
    else
        installMySQL=true
    fi
fi

if [ "${installMySQL}" = false ]; then
    # We need to get additional values
    [ -z "${mysqlHost}" ] \
      && read -p "Enter MySQL server hostname or IP: " mysqlHost
    [ -z "${mysqlPort}" ] \
      && read -p "Enter MySQL server port [3306]: " mysqlPort
    [ -z "${guacDb}" ] \
      && read -p "Enter Guacamole database name [guacamole_db]: " guacDb
    [ -z "${guacUser}" ] \
      && read -p "Enter Guacamole user [guacamole_user]: " guacUser
fi

# Checking if mysql host given
if [ -z "${mysqlHost}" ]; then
    mysqlHost="localhost"
fi

# Checking if mysql port given
if [ -z "${mysqlPort}" ]; then
    mysqlPort="3306"
fi

# Checking if mysql user given
if [ -z "${guacUser}" ]; then
    guacUser="guacamole_user"
fi

# Checking if database name given
if [ -z "${guacDb}" ]; then
    guacDb="guacamole_db"
fi

if [ -z "${mysqlRootPwd}" ]; then
    # Get MySQL "Root" and "Guacamole User" password
    while true; do
##@@## Fix colours
echo -e "${YELLOW}"
        echo
        read -s -p "Enter ${mysqlHost}'s MySQL root password: " mysqlRootPwd
        echo
        read -s -p "Confirm ${mysqlHost}'s MySQL root password: " PROMPT2
        echo
        [ "${mysqlRootPwd}" = "${PROMPT2}" ] && break
        echo -e "${RED}Passwords don't match. Please try again.${NC}" 1>&2
    done
else
##@@##
    echo -e "${YELLOW}Read MySQL root's password from command line argument${NC}"
fi
echo

if [ -z "${guacPwd}" ]; then
    while true; do
##@@## Fix colours	
	echo -e "${BLUE}"
        echo -e "${BLUE}A new MySQL user will be created (${guacUser})"
        read -s -p "Enter ${mysqlHost}'s MySQL guacamole user password: " guacPwd
        echo
        read -s -p "Confirm ${mysqlHost}'s MySQL guacamole user password: " PROMPT2
        echo
        [ "${guacPwd}" = "${PROMPT2}" ] && break
        echo -e "${RED}Passwords don't match. Please try again.${NC}" 1>&2
        echo
    done
else
    echo -e "${BLUE}Read MySQL ${guacUser}'s password from command line argument${NC}"
fi
echo

if [ "${installMySQL}" = true ]; then
    # Seed MySQL install values
    debconf-set-selections <<< "mysql-server mysql-server/root_password password ${mysqlRootPwd}"
    debconf-set-selections <<< "mysql-server mysql-server/root_password_again password ${mysqlRootPwd}"
fi

##@@## Update OS and install Nginx while we are at it  
	sudo apt update && sudo apt upgrade -y && apt install nginx -y && sudo apt install pwgen -y

# Different version of Ubuntu/Linux Mint and Debian have different package names...
source /etc/os-release
if [[ "${NAME}" == "Ubuntu" ]] || [[ "${NAME}" == "Linux Mint" ]]; then
    # Ubuntu > 18.04 does not include universe repo by default
    # Add the "Universe" repo, don't update
    add-apt-repository -y universe
    # Set package names depending on version
    JPEGTURBO="libjpeg-turbo8-dev"
    if [[ "${VERSION_ID}" == "16.04" ]]; then
        LIBPNG="libpng12-dev"
##@@## Enable ufw regradless of Ubuntu version - ufw must be active for rules to be applied by this script 
	echo "y" | sudo ufw enable  
    else
        LIBPNG="libpng-dev"
##@@## Enable ufw regradless of Ubuntu version - ufw must be active for rules to be applied by this script
	echo "y" | sudo ufw enable 
##@@## Turn off cloud init.
sudo touch /etc/cloud/cloud-init.disabled

    fi
    if [ "${installMySQL}" = true ]; then
        MYSQL="mysql-server mysql-client mysql-common"
    # Checking if (any kind of) mysql-client or compatible command installed. This is useful for existing mariadb server
    elif [ -x "$( command -v mysql )" ]; then
        MYSQL=""
    else
        MYSQL="mysql-client"
    fi
elif [[ "${NAME}" == *"Debian"* ]] || [[ "${NAME}" == *"Raspbian GNU/Linux"* ]] || [[ "${NAME}" == *"Kali GNU/Linux"* ]] || [[ "${NAME}" == "LMDE" ]]; then
    JPEGTURBO="libjpeg62-turbo-dev"
    if [[ "${PRETTY_NAME}" == *"bullseye"* ]] || [[ "${PRETTY_NAME}" == *"stretch"* ]] || [[ "${PRETTY_NAME}" == *"buster"* ]] || [[ "${PRETTY_NAME}" == *"Kali GNU/Linux Rolling"* ]] || [[ "${NAME}" == "LMDE" ]]; then
        LIBPNG="libpng-dev"
##@@## Install ufw and unattended-upgrades as its not installed by default on Raspian 		
		apt install ufw -y
		apt install unattended-upgrades -y
		echo "y" | sudo ufw enable
    else
        LIBPNG="libpng12-dev"
    fi
    if [ "${installMySQL}" = true ]; then
        MYSQL="default-mysql-server default-mysql-client mysql-common"
    # Checking if (any kind of) mysql-client or compatible command installed. This is useful for existing mariadb server
    elif [ -x "$( command -v mysql )" ]; then
        MYSQL=""
    else
        MYSQL="default-mysql-client"
    fi
else
    echo "Unsupported distribution - Debian, Kali, Raspbian, Linux Mint or Ubuntu only"
    exit 1
fi

# Update apt so we can search apt-cache for newest Tomcat version supported & libmariadb-java/libmysql-java
echo -e "${BLUE}Updating apt...${NC}"
apt-get -qq update

# Check if libmariadb-java/libmysql-java is available
# Debian 10 >= ~ https://packages.debian.org/search?keywords=libmariadb-java
if [[ $( apt-cache show libmariadb-java 2> /dev/null | wc -l ) -gt 0 ]]; then
    # When something higher than 1.1.0 is out ~ https://issues.apache.org/jira/browse/GUACAMOLE-852
    #echo -e "${BLUE}Found libmariadb-java package...${NC}"
    #LIBJAVA="libmariadb-java"
    # For v1.1.0 and lower
    echo -e "${YELLOW}Found libmariadb-java package (known issues). Will download libmysql-java ${MCJVER} and install manually${NC}"
    LIBJAVA=""
# Debian 9 <= ~ https://packages.debian.org/search?keywords=libmysql-java
elif [[ $( apt-cache show libmysql-java 2> /dev/null | wc -l ) -gt 0 ]]; then
    echo -e "${BLUE}Found libmysql-java package...${NC}"
    LIBJAVA="libmysql-java"
else
    echo -e "${YELLOW}lib{mariadb,mysql}-java not available. Will download mysql-connector-java-${MCJVER}.tar.gz and install manually${NC}"
    LIBJAVA=""
fi

# tomcat9 is the latest version
# tomcat8.0 is end of life, but tomcat8.5 is current
# fallback is tomcat7
if [[ $( apt-cache show tomcat9 2> /dev/null | egrep "Version: 9" | wc -l ) -gt 0 ]]; then
    echo -e "${BLUE}Found tomcat9 package...${NC}"
    TOMCAT="tomcat9"
elif [[ $( apt-cache show tomcat8 2> /dev/null | egrep "Version: 8.[5-9]" | wc -l ) -gt 0 ]]; then
    echo -e "${BLUE}Found tomcat8.5+ package...${NC}"
    TOMCAT="tomcat8"
elif [[ $( apt-cache show tomcat7 2> /dev/null | egrep "Version: 7" | wc -l ) -gt 0 ]]; then
    echo -e "${BLUE}Found tomcat7 package...${NC}"
    TOMCAT="tomcat7"
else
    echo -e "${RED}Failed. Can't find Tomcat package${NC}" 1>&2
    exit 1
fi

# Uncomment to manually force a Tomcat version
#TOMCAT=""

# Install features
echo -e "${BLUE}Installing packages. This might take a few minutes...${NC}"

# Don't prompt during install
export DEBIAN_FRONTEND=noninteractive

# Required packages
apt-get -y install build-essential libcairo2-dev ${JPEGTURBO} ${LIBPNG} libossp-uuid-dev libavcodec-dev libavformat-dev libavutil-dev \
libswscale-dev freerdp2-dev libpango1.0-dev libssh2-1-dev libtelnet-dev libvncserver-dev libpulse-dev libssl-dev \
libvorbis-dev libwebp-dev libwebsockets-dev freerdp2-x11 libtool-bin ghostscript dpkg-dev wget crudini libc-bin \
${MYSQL} ${LIBJAVA} ${TOMCAT} &>> ${LOG}

# If apt fails to run completely the rest of this isn't going to work...
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed. See ${LOG}${NC}" 1>&2
    exit 1
else
    echo -e "${GREEN}OK${NC}"
fi
echo

# Set SERVER to be the preferred download server from the Apache CDN
SERVER="http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUACVERSION}"
echo -e "${BLUE}Downloading files...${NC}"

# Download Guacamole Server
wget -q --show-progress -O guacamole-server-${GUACVERSION}.tar.gz ${SERVER}/source/guacamole-server-${GUACVERSION}.tar.gz
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to download guacamole-server-${GUACVERSION}.tar.gz" 1>&2
    echo -e "${SERVER}/source/guacamole-server-${GUACVERSION}.tar.gz${NC}"
    exit 1
else
    # Extract Guacamole Files
    tar -xzf guacamole-server-${GUACVERSION}.tar.gz
fi
echo -e "${GREEN}Downloaded guacamole-server-${GUACVERSION}.tar.gz${NC}"

# Download Guacamole Client
wget -q --show-progress -O guacamole-${GUACVERSION}.war ${SERVER}/binary/guacamole-${GUACVERSION}.war
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to download guacamole-${GUACVERSION}.war" 1>&2
    echo -e "${SERVER}/binary/guacamole-${GUACVERSION}.war${NC}"
    exit 1
fi
echo -e "${GREEN}Downloaded guacamole-${GUACVERSION}.war${NC}"

# Download Guacamole authentication extensions (Database)
wget -q --show-progress -O guacamole-auth-jdbc-${GUACVERSION}.tar.gz ${SERVER}/binary/guacamole-auth-jdbc-${GUACVERSION}.tar.gz
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to download guacamole-auth-jdbc-${GUACVERSION}.tar.gz" 1>&2
    echo -e "${SERVER}/binary/guacamole-auth-jdbc-${GUACVERSION}.tar.gz"
    exit 1
else
    tar -xzf guacamole-auth-jdbc-${GUACVERSION}.tar.gz
fi
echo -e "${GREEN}Downloaded guacamole-auth-jdbc-${GUACVERSION}.tar.gz${NC}"

# Download Guacamole authentication extensions

# TOTP
if [ "${installTOTP}" = true ]; then
    wget -q --show-progress -O guacamole-auth-totp-${GUACVERSION}.tar.gz ${SERVER}/binary/guacamole-auth-totp-${GUACVERSION}.tar.gz
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to download guacamole-auth-totp-${GUACVERSION}.tar.gz" 1>&2
        echo -e "${SERVER}/binary/guacamole-auth-totp-${GUACVERSION}.tar.gz"
        exit 1
    else
        tar -xzf guacamole-auth-totp-${GUACVERSION}.tar.gz
    fi
    echo -e "${GREEN}Downloaded guacamole-auth-totp-${GUACVERSION}.tar.gz${NC}"
fi

# Duo
if [ "${installDuo}" = true ]; then
    wget -q --show-progress -O guacamole-auth-duo-${GUACVERSION}.tar.gz ${SERVER}/binary/guacamole-auth-duo-${GUACVERSION}.tar.gz
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to download guacamole-auth-duo-${GUACVERSION}.tar.gz" 1>&2
        echo -e "${SERVER}/binary/guacamole-auth-duo-${GUACVERSION}.tar.gz"
        exit 1
    else
        tar -xzf guacamole-auth-duo-${GUACVERSION}.tar.gz
    fi
    echo -e "${GREEN}Downloaded guacamole-auth-duo-${GUACVERSION}.tar.gz${NC}"
fi

# Deal with missing MySQL Connector/J
if [[ -z $LIBJAVA ]]; then
    # Download MySQL Connector/J
    wget -q --show-progress -O mysql-connector-java-${MCJVER}.tar.gz https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-${MCJVER}.tar.gz
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to download mysql-connector-java-${MCJVER}.tar.gz" 1>&2
        echo -e "https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-${MCJVER}.tar.gz${NC}"
        exit 1
    else
        tar -xzf mysql-connector-java-${MCJVER}.tar.gz
    fi
    echo -e "${GREEN}Downloaded mysql-connector-java-${MCJVER}.tar.gz${NC}"
else
    echo -e "${YELLOW}Skipping manually installing MySQL Connector/J${NC}"
fi
echo -e "${GREEN}Downloading complete.${NC}"
echo

# Make directories
rm -rf /etc/guacamole/lib/
rm -rf /etc/guacamole/extensions/
mkdir -p /etc/guacamole/lib/
mkdir -p /etc/guacamole/extensions/

# Fix for #196
mkdir -p /usr/sbin/.config/freerdp
chown daemon:daemon /usr/sbin/.config/freerdp

# Fix for #197
mkdir -p /var/guacamole
chown daemon:daemon /var/guacamole

# Install guacd (Guacamole-server)
cd guacamole-server-${GUACVERSION}/

echo -e "${BLUE}Building Guacamole-Server with GCC $( gcc --version | head -n1 | grep -oP '\)\K.*' | awk '{print $1}' ) ${NC}"

# Fix for warnings #222
export CFLAGS="-Wno-error"

echo -e "${BLUE}Configuring Guacamole-Server. This might take a minute...${NC}"
./configure --with-systemd-dir=/etc/systemd/system  &>> ${LOG}
if [ $? -ne 0 ]; then
    echo "Failed to configure guacamole-server"
    echo "Trying again with --enable-allow-freerdp-snapshots"
    ./configure --with-systemd-dir=/etc/systemd/system --enable-allow-freerdp-snapshots
    if [ $? -ne 0 ]; then
        echo "Failed to configure guacamole-server - again"
        exit
    fi
else
    echo -e "${GREEN}OK${NC}"
fi

echo -e "${BLUE}Running Make on Guacamole-Server. This might take a few minutes...${NC}"
make &>> ${LOG}
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed. See ${LOG}${NC}" 1>&2
    exit 1
else
    echo -e "${GREEN}OK${NC}"
fi

echo -e "${BLUE}Running Make Install on Guacamole-Server...${NC}"
make install &>> ${LOG}
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed. See ${LOG}${NC}" 1>&2
    exit 1
else
    echo -e "${GREEN}OK${NC}"
fi
ldconfig
echo

# Move files to correct locations (guacamole-client & Guacamole authentication extensions)
cd ..
mv -f guacamole-${GUACVERSION}.war /etc/guacamole/guacamole.war
mv -f guacamole-auth-jdbc-${GUACVERSION}/mysql/guacamole-auth-jdbc-mysql-${GUACVERSION}.jar /etc/guacamole/extensions/

# Create Symbolic Link for Tomcat
ln -sf /etc/guacamole/guacamole.war /var/lib/${TOMCAT}/webapps/

# Deal with MySQL Connector/J
if [[ -z $LIBJAVA ]]; then
    echo -e "${BLUE}Moving mysql-connector-java-${MCJVER}.jar (/etc/guacamole/lib/mysql-connector-java.jar)...${NC}"
    mv -f mysql-connector-java-${MCJVER}/mysql-connector-java-${MCJVER}.jar /etc/guacamole/lib/mysql-connector-java.jar
elif [ -e /usr/share/java/mariadb-java-client.jar ]; then
    echo -e "${BLUE}Linking mariadb-java-client.jar  (/etc/guacamole/lib/mariadb-java-client.jar)...${NC}"
    ln -sf /usr/share/java/mariadb-java-client.jar /etc/guacamole/lib/mariadb-java-client.jar
elif [ -e /usr/share/java/mysql-connector-java.jar ]; then
    echo -e "${BLUE}Linking mysql-connector-java.jar  (/etc/guacamole/lib/mysql-connector-java.jar)...${NC}"
    ln -sf /usr/share/java/mysql-connector-java.jar /etc/guacamole/lib/mysql-connector-java.jar
else
    echo -e "${RED}Can't find *.jar file${NC}" 1>&2
    exit 1
fi
echo

# Move TOTP Files
if [ "${installTOTP}" = true ]; then
    echo -e "${BLUE}Moving guacamole-auth-totp-${GUACVERSION}.jar (/etc/guacamole/extensions/)...${NC}"
    mv -f guacamole-auth-totp-${GUACVERSION}/guacamole-auth-totp-${GUACVERSION}.jar /etc/guacamole/extensions/
    echo
fi

# Move Duo Files
if [ "${installDuo}" = true ]; then
    echo -e "${BLUE}Moving guacamole-auth-duo-${GUACVERSION}.jar (/etc/guacamole/extensions/)...${NC}"
    mv -f guacamole-auth-duo-${GUACVERSION}/guacamole-auth-duo-${GUACVERSION}.jar /etc/guacamole/extensions/
    echo
fi

# Configure guacamole.properties
rm -f /etc/guacamole/guacamole.properties
touch /etc/guacamole/guacamole.properties
echo "mysql-hostname: ${mysqlHost}" >> /etc/guacamole/guacamole.properties
echo "mysql-port: ${mysqlPort}" >> /etc/guacamole/guacamole.properties
echo "mysql-database: ${guacDb}" >> /etc/guacamole/guacamole.properties
echo "mysql-username: ${guacUser}" >> /etc/guacamole/guacamole.properties
echo "mysql-password: ${guacPwd}" >> /etc/guacamole/guacamole.properties

# Output Duo configuration settings but comment them out for now
if [ "${installDuo}" = true ]; then
    echo "# duo-integration-key: " >> /etc/guacamole/guacamole.properties
	echo "# duo-api-hostname: " >> /etc/guacamole/guacamole.properties
    echo "# duo-secret-key: " >> /etc/guacamole/guacamole.properties
    echo "# duo-application-key: " >> /etc/guacamole/guacamole.properties
    echo -e "${YELLOW}Duo is installed, it will need to be configured via guacamole.properties${NC}"
fi

# Restart Tomcat
echo -e "${BLUE}Restarting Tomcat service & enable at boot...${NC}"
service ${TOMCAT} restart
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed${NC}" 1>&2
    exit 1
else
    echo -e "${GREEN}OK${NC}"
fi
# Start at boot
systemctl enable ${TOMCAT}
echo

# Set MySQL password
export MYSQL_PWD=${mysqlRootPwd}

if [ "${installMySQL}" = true ]; then

    # Restart MySQL service
    echo -e "${BLUE}Restarting MySQL service & enable at boot...${NC}"
    service mysql restart
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed${NC}" 1>&2
        exit 1
    else
        echo -e "${GREEN}OK${NC}"
    fi
    # Start at boot
    systemctl enable mysql
    echo

    # Default locations of MySQL config file
    for x in /etc/mysql/mariadb.conf.d/50-server.cnf \
             /etc/mysql/mysql.conf.d/mysqld.cnf \
             /etc/mysql/my.cnf \
             ; do
        # Check the path exists
        if [ -e "${x}" ]; then
            # Does it have the necessary section
            if grep -q '^\[mysqld\]$' "${x}"; then
                mysqlconfig="${x}"
                # no point keep checking!
                break
            fi
        fi
    done

    if [ -z "${mysqlconfig}" ]; then
        echo -e "${YELLOW}Couldn't detect MySQL config file - you may need to manually enter timezone settings${NC}"
    else
        # Is there already a value?
        if grep -q "^default_time_zone[[:space:]]?=" "${mysqlconfig}"; then
            echo -e "${YELLOW}Timezone already defined in ${mysqlconfig}${NC}"
        else
            timezone="$( cat /etc/timezone )"
            if [ -z "${timezone}" ]; then
                echo -e "${YELLOW}Couldn't find timezone, using UTC${NC}"
                timezone="UTC"
            fi
            echo -e "${YELLOW}Setting timezone as ${timezone}${NC}"
            # Fix for https://issues.apache.org/jira/browse/GUACAMOLE-760
            mysql_tzinfo_to_sql /usr/share/zoneinfo 2>/dev/null | mysql -u root -D mysql -h ${mysqlHost} -P ${mysqlPort}
            crudini --set ${mysqlconfig} mysqld default_time_zone "${timezone}"
            # Restart to apply
            service mysql restart
            echo
        fi
    fi
fi

# Create ${guacDb} and grant ${guacUser} permissions to it

# SQL code
guacUserHost="localhost"

if [[ "${mysqlHost}" != "localhost" ]]; then
    guacUserHost="%"
    echo -e "${YELLOW}MySQL Guacamole user is set to accept login from any host, please change this for security reasons if possible.${NC}"
fi

# Check for ${guacDb} already being there
echo -e "${BLUE}Checking MySQL for existing database (${guacDb})${NC}"
SQLCODE="
SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME='${guacDb}';"

# Execute SQL code
MYSQL_RESULT=$( echo ${SQLCODE} | mysql -u root -D information_schema -h ${mysqlHost} -P ${mysqlPort} )
if [[ $MYSQL_RESULT != "" ]]; then
    echo -e "${RED}It appears there is already a MySQL database (${guacDb}) on ${mysqlHost}${NC}" 1>&2
    echo -e "${RED}Try:    mysql -e 'DROP DATABASE ${guacDb}'${NC}" 1>&2
    #exit 1
else
    echo -e "${GREEN}OK${NC}"
fi

# Check for ${guacUser} already being there
echo -e "${BLUE}Checking MySQL for existing user (${guacUser})${NC}"
SQLCODE="
SELECT COUNT(*) FROM mysql.user WHERE user = '${guacUser}';"

# Execute SQL code
MYSQL_RESULT=$( echo ${SQLCODE} | mysql -u root -D mysql -h ${mysqlHost} -P ${mysqlPort} | grep '0' )
if [[ $MYSQL_RESULT == "" ]]; then
    echo -e "${RED}It appears there is already a MySQL user (${guacUser}) on ${mysqlHost}${NC}" 1>&2
    echo -e "${RED}Try:    mysql -e \"DROP USER '${guacUser}'@'${guacUserHost}'; FLUSH PRIVILEGES;\"${NC}" 1>&2
    #exit 1
else
    echo -e "${GREEN}OK${NC}"
fi

# Create database & user, then set permissions
SQLCODE="
DROP DATABASE IF EXISTS ${guacDb};
CREATE DATABASE IF NOT EXISTS ${guacDb};
CREATE USER IF NOT EXISTS '${guacUser}'@'${guacUserHost}' IDENTIFIED BY \"${guacPwd}\";
GRANT SELECT,INSERT,UPDATE,DELETE ON ${guacDb}.* TO '${guacUser}'@'${guacUserHost}';
FLUSH PRIVILEGES;"

# Execute SQL code
echo ${SQLCODE} | mysql -u root -D mysql -h ${mysqlHost} -P ${mysqlPort}

# Add Guacamole schema to newly created database
echo -e "${BLUE}Adding database tables...${NC}"
cat guacamole-auth-jdbc-${GUACVERSION}/mysql/schema/*.sql | mysql -u root -D ${guacDb} -h ${mysqlHost} -P ${mysqlPort}
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed${NC}" 1>&2
    exit 1
else
    echo -e "${GREEN}OK${NC}"
fi
echo

##@@## Create guacd.conf file required for 1.4.0
echo -e "${BLUE}Create guacd.conf file...${NC}"
cat >> /etc/guacamole/guacd.conf <<- "EOF"
[server]
bind_host = 127.0.0.1
bind_port = 4822
EOF

# Ensure guacd is started
echo -e "${BLUE}Starting guacd service & enable at boot...${NC}"
service guacd stop 2>/dev/null
service guacd start
systemctl enable guacd
echo

# Deal with ufw and/or iptables

# Check if ufw is a valid command
if [ -x "$( command -v ufw )" ]; then
    # Check if ufw is active (active|inactive)
    if [[ $(ufw status | grep inactive | wc -l) -eq 0 ]]; then
        # Check if 8080 is not already allowed
        if [[ $(ufw status | grep "8080/tcp" | grep "ALLOW" | grep "Anywhere" | wc -l) -eq 0 ]]; then
            ##@@## If ufw is running, add the appropriate rules
            ufw default allow outgoing
			ufw default deny incoming
			ufw deny 8080/tcp comment 'deny tomcat force access via Nginx'
			ufw allow OpenSSH comment 'allow ssh and winscp'
			ufw allow 80/tcp comment 'allow http'
			ufw allow 443/tcp comment 'allow https'
        fi
    fi
fi    

# Cleanup
echo -e "${BLUE}Cleanup install files...${NC}"
rm -rf guacamole-*
rm -rf mysql-connector-java-*
unset MYSQL_PWD
echo


##@@## Make sure unattended upgrades are turned on.
systemctl enable unattended-upgrades
systemctl start unattended-upgrades

###@@## Allow automatic updates to reboot the system 
sudo sed -i '/Unattended-Upgrade::Automatic-Reboot "false";/a\Unattended-Upgrade::Automatic-Reboot "true";' /etc/apt/apt.conf.d/50unattended-upgrades
sudo systemctl restart unattended-upgrades.service

##@@## Apt clean up
sudo apt autoremove -y && sudo apt autoclean -y

##@##Set Guacamole URL
guacamoleurl=http://localhost:8080/guacamole/

##@@## Configure /etc/nginx/sites-available/(website name)
cat >/etc/nginx/sites-available/$website <<EOL
server {
    listen 80 default_server;
    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;
    server_name $website;
    location / {
        proxy_pass $guacamoleurl;
        proxy_buffering off;
        proxy_http_version 1.1;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$http_connection;
        access_log off;
    }
}
EOL

##@@## symlink from sites-available to sites-enabled
ln -s /etc/nginx/sites-available/$website /etc/nginx/sites-enabled/

##@@## make sure default is unlinked
unlink /etc/nginx/sites-enabled/default

##@@## Do mandatory Nginx tweaks for logging actual client IPs, not proxy IP 127.0.0.1 DO NOT CHANGE COMMAND FORMATING
sudo sed -i '/pattern="%h %l %u %t &quot;%r&quot; %s %b"/a        \        <!-- Allow host IP to pass through to guacamole.-->\n        <Valve className="org.apache.catalina.valves.RemoteIpValve"\n               internalProxies="127.0.0.1"\n               remoteIpHeader="x-forwarded-for"\n               remoteIpProxiesHeader="x-forwarded-by"\n               protocolHeader="x-forwarded-proto" />' /etc/${TOMCAT}/server.xml

##@@## Allow larger file transfers through Nginx
sudo sed -i "/Basic Settings/a \        client_max_body_size 1000000M;" /etc/nginx/nginx.conf

##@@##Nginx somtimes needs a double bounce to avoid a restart
sudo systemctl start nginx
sudo systemctl restart ${TOMCAT}
sudo systemctl restart guacd
sudo systemctl restart nginx
sleep 2
sudo systemctl restart nginx
sudo systemctl restart ${TOMCAT}
sudo systemctl restart guacd
sudo systemctl restart nginx

##@@## Set internet NPT servers
cat <<EOF | sudo tee /etc/systemd/timesyncd.conf
[Time]
NTP=time.google.com time.windows.com
RootDistanceMaxSec=5
PollIntervalMinSec=32
PollIntervalMaxSec=2048
EOF
sudo systemctl restart systemd-timesyncd.service

echo -e "${BLUE}Installation Complete\n- Visit: http://localhost:8080/guacamole/\n- Default login (username/password): guacadmin/guacadmin\n***Be sure to change the password***.${NC}"

##@@## Duo Settings reminder
if [ "${installDuo}" = true ]; then
echo -e "${YELLOW}+---------------------------------------------------------------------------------------------------------------------------"
    echo -e "${YELLOW}\nDon't forget to configure Duo in guacamole.properties. You will not be able to login otherwise.\nhttps://guacamole.apache.org/doc/${GUACVERSION}/gug/duo-auth.html${NC}"
	echo "You must set up your Duo account with a new 'Web SDK' application and copy the relevant API settings"
	echo "sudo nano /etc/guacamole/guacamole.properties"
	echo "duo-integration-key: DI90PT03UKWOVAWA2LAK"
	echo "duo-api-hostname: api-8e25b967.duosecurity.com"
	echo "duo-secret-key: fdRIVzpPhhGnxLGC7Fk4zZtQRpIUmBqdrna0lQYI"
	echo "duo-application-key: ohyaedas7aighooquai6Eezeonie5ughee0phook (run 'pwgen 40 1' to manually generate this 40 char random value)"
	echo "Then restart Guacamole with sudo systemctl restart ${TOMCAT}"
fi

##@@## Set timezone reminder
printf "${PURPLE}+---------------------------------------------------------------------------------------------------------------------------
+ Remember To Set Timezone:
+
+ Run${YELLOW} timedatectl list-timezones${PURPLE}
+ Browse the list of timezones and identify your closest zone name
+ the run ${YELLOW}timedatectl set-timezone Country/City${PURPLE}
+ e.g. sudo timedatectl set-timezone Australia/Melbourne
+---------------------------------------------------------------------------------------------------------------------------\n${NC}"
printf "${CYAN}+---------------------------------------------------------------------------------------------------------------------------
+ For instructions on completing your jump server build, please see ${YELLOW}Guac-Completion-Tasks.doc ${CYAN} in your Linux home directory.
+
+ This document explains the current configuration and the final steps towards completing your high security appliance.
+ 
+ To aid with final steps, various configuration scripts and app extensions have also been added to your home directory.

+---------------------------------------------------------------------------------------------------------------------------\n${NC}"






