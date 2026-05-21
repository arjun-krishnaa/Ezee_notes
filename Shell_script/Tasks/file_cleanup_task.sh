#!/bin/bash

SRC="/home/backup"
DATE=$(TZ="Asia/Kolkata" date +"%d-%m-%y_%H-%M-%S")
LOG="/home/txt_files/cleanup.txt"

touch "$LOG"

if find "$SRC" -type f -mtime 0.5days -size +2k  -print -delete  : then
    echo "file cleanup at $DATE was successful" >> $LOG
else
    echo "file cleanup at $DATE was failure" >> $LOG
fi

----------------------------------------------------------------------------

!/bin/bash

SRC="/home/notes/notes/Notes/Tomcat"
DATE=$(TZ="Asia/Kolkata" date +"%d-%m-%y_%H-%M-%S")
LOG="/home/txt_files/cleanup.txt"

touch "$LOG"

ls -lrta "$SRC" >> "$LOG"

if find "$SRC" -type f -mtime +0  -size +1k -print -delete  >> $LOG ; then
    echo "file cleanup at $DATE was successful" >> $LOG
else
    echo "file cleanup at $DATE was failure" >> $LOG
    exit 1
fi

ls -lrta "$SRC" >> "$LOG"


-------------------------------------------------------------------------------

#!/bin/bash

SRC="/home/notes/notes/Notes/Tomcat"
DATE=$(TZ="Asia/Kolkata" date +"%d-%m-%y_%H-%M-%S")
LOG="/home/txt_files/cleanup.txt"

# Create log file
touch "$LOG"

ls -lrta "$SRC" >> "$LOG"

# Check directory exists
if [ ! -d "$SRC" ]; then
    echo "$DATE : Source directory not found. Cleanup failed." >> "$LOG"
    exit 1
fi

# Cleanup files older than 1 day and larger than 2KB
if find "$SRC" -type f -mtime +0 -size +1k -print -delete >> "$LOG" 2>&1; then
    echo "$DATE : File cleanup was successful." >> "$LOG"
else
    echo "$DATE : File cleanup failed." >> "$LOG"
    exit 1
fi

ls -lrta "$SRC" >> "$LOG"
