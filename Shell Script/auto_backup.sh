#!/bin/bash

SRC="/var/log/syslog"  
DEST="/home/log_backup"
LOG="$DEST/backup.txt"
DATE=$(date +"%d-%m-%y_%H-%M-%S")
BACKUP_FILE="$DEST/backup_log_$DATE.tar.gz"

#Create Dir

mkdir -p "$DEST"

#create txt file

touch "$LOG"

echo "Backup Started at $DATE" >> $LOG

tar -cpzf "$BACKUP_FILE" "$SRC"

echo "File created at $DATE" >> $LOG

echo "Backup successfull" >> $LOG

echo "---------------------" >> $LOG

----------------------------------------------------------------------------

# indian time zone

#IST_TIME=$(TZ="Asia/Kolkata" date +"%Y-%m-%d %H:%M:%S")

#!/bin/bash

SRC="/var/log/syslog"  
DEST="/home/log_backup"
LOG="$DEST/backup.txt"
DATE=$(TZ="Asia/Kolkata" date +"%d-%m-%y_%H-%M-%S")
#DATE=$(date +"%d-%m-%y_%H-%M-%S")
BACKUP_FILE="$DEST/backup_log_$DATE.tar.gz"

#Create Dir

mkdir -p "$DEST"

#create txt file

touch "$LOG"

echo "Backup Started at $DATE" >> $LOG

tar -cpzf "$BACKUP_FILE" "$SRC"

echo "File created at $DATE" >> $LOG

echo "Backup successfull" >> $LOG

echo "---------------------" >> $LOG