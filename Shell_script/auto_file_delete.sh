#!/bin/bash

SRC="/home/log_backup"
DATE=$(TZ="Asia/Kolkata" date +"%d-%m-%y_%H-%M-%S")
FILE="/home/del_file_log.txt"

# Create log file if not exists
touch "$FILE"

# Check if source directory exists
if [ ! -d "$SRC" ]; then
    echo "Source directory not found: $SRC" >> "$FILE"
    exit 1
fi

# List files before deletion
echo "File list before deletion ($DATE):" >> "$FILE"
ls -lrta "$SRC" >> "$FILE"

# Delete files older than 5 days
find "$SRC" -type f -size +100k -print -delete >> "$FILE" 2>&1

# Log completion
echo "Files older than 5 days deleted on $DATE" >> "$FILE"
echo "----------------------------------------" >> "$FILE"
