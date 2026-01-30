#!/bin/bash

LOG_DIR="/home/txt_files"
DATE=$(date +"%Y-%m-%d")
RETENTION_DAYS=7

cd "$LOG_DIR" || exit 1

# Rotate logs: .log → .log.DATE
for file in *.log; do
    [ -f "$file" ] || continue
    mv "$file" "$file.$DATE"
    gzip "$file.$DATE"
done

# Delete logs older than 7 days
find "$LOG_DIR" -name "*.gz" -mtime +$RETENTION_DAYS -delete
