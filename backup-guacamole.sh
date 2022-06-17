#!/bin/bash
################################################################
## Guacamole MySQL Database Backup
## David Harrop
## April 2022
################################################################

export PATH=/bin:/usr/bin:/usr/local/bin
TODAY=`date +%Y-%m-%d`
################################################################
################## Update below values ########################

DB_BACKUP_PATH='/home/pax8/mysqlbackups/'
MYSQL_HOST='localhost'
MYSQL_PORT='3306'
MYSQL_USER='root'
MYSQL_PASSWORD='pax8'
DATABASE_NAME='guacamole_db'
BACKUP_RETAIN_DAYS=30 ## Number of days to keep local backup copy
RECIPIENT_EMAIL=yourname@gmail.com

#################################################################

mkdir -p ${DB_BACKUP_PATH}
echo "Backup started for database - ${DATABASE_NAME}"

mysqldump -h ${MYSQL_HOST} \
-P ${MYSQL_PORT} \
-u ${MYSQL_USER} \
-p${MYSQL_PASSWORD} \
${DATABASE_NAME} \
 --single-transaction --quick --lock-tables=false > \
${DB_BACKUP_PATH}${DATABASE_NAME}-${TODAY}.sql 
SQLFILE=${DB_BACKUP_PATH}${DATABASE_NAME}-${TODAY}.sql 
gzip -f ${SQLFILE} 

#Error check and email alert
if [ $? -eq 0 ]; then
echo "Guacamomle Database Backup Success" | mailx -s "Guacamomle Database Backup Success" ${RECIPIENT_EMAIL} 
else
echo "Guacamomle Database Backup Failed" | mailx -s "Guacamomle Database Backup failed" ${RECIPIENT_EMAIL} 
exit 1
fi

#Protect disk space and remove backups older than {BACKUP_RETAIN_DAYS} days 
find ${DB_BACKUP_PATH} -mtime +${BACKUP_RETAIN_DAYS} -delete
