#!bin/bash
------------------------------------
#Task:
#Write a shell script to:
#Take backup of /home/user/data  = /home/txt_files
#Store it in /backup
#Append date & time to backup file name
#Log success/failure
---------------------------------------
SRC="/home/txt_files"
DEST="/home/backup"
DATE=$(TZ="Asia/kolkatta" date +"%d-%m-%y_%H-%M-%S")
LOG="/home/backup/backtask.txt"

mkdir -p "$DEST"

touch "$LOG"

tar -cpzf "$DEST/txt_backup_$DATE.tar.gz" "$SRC" >> $LOG 2>&1

if [ ! -d "$SRC"] ; then
    echo "backup is failed" >> $LOG
    exit 1
fi

echo "backup sucessful" >> $LOG

--------------------------------------------------------------------
# CHAT GPT

#!/bin/bash

SRC="/home/txt_files"
DEST="/home/backup"
DATE=$(TZ="Asia/Kolkata" date +"%d-%m-%y_%H-%M-%S")
LOG="/home/backup/backtask.txt"

# Create destination directory
mkdir -p "$DEST"

# Create log file if not exists
touch "$LOG"

# Check source directory exists BEFORE backup
if [ ! -d "$SRC" ]; then
    echo "$(date) : Source directory not found. Backup failed." >> "$LOG"
    exit 1
fi

# Take backup
tar -cpzf "$DEST/txt_backup_$DATE.tar.gz" "$SRC" >> "$LOG" 2>&1

# Check backup status
if [ $? -eq 0 ]; then
    echo "$(date) : Backup successful." >> "$LOG"
else
    echo "$(date) : Backup failed." >> "$LOG"
    exit 1
fi

=========================================================================

#!/bin/bash

SRC="/home/txt_files"
DEST="/home/backup"
DATE=$(TZ="Asia/Kolkata" date +"%d-%m-%y_%H-%M-%S")
LOG="/home/backup/backtask.txt"

mkdir -p "$DEST"
touch "$LOG"

# Check source directory
if [ ! -d "$SRC" ]; then
    echo "$(date) : Source directory not found. Backup failed." >> "$LOG"
    exit 1
fi

# Change to parent directory of SRC
cd "$(dirname "$SRC")" || exit 1

# Take backup (relative path)
tar -cpzf "$DEST/txt_backup_$DATE.tar.gz" "$(basename "$SRC")" >> "$LOG" 2>&1

# Verify backup
if [ $? -eq 0 ]; then
    echo "$(date) : Backup successful." >> "$LOG"
else
    echo "$(date) : Backup failed." >> "$LOG"
    exit 1
fi




