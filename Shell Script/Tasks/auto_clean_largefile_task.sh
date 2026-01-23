#!/bin/bash

SRC="/home/notes/notes/Notes/Linux docs/linuxdocs"
DATE=$(TZ="Asia/Kolkata" date +"%d-%m-%Y %H:%M:%S")
LOG_FILE="/home/txt_files/larg_file_del.txt"

touch "$LOG_FILE"
echo "FILES IN $SRC ON DATE: $DATE"  >> "$LOG_FILE"


ls -lrta | find "$SRC" -type f -size +500k  >> "$LOG_FILE"

if find "$SRC" -type f -size +500k -print -delete; then
    echo "File more 500kb size were deleted succesfully" >> "$LOG_FILE"
    
 else
    echo "File more 500kb size were not found" >> "$LOG_FILE"
    
fi
