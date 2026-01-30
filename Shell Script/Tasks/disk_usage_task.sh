#!/bin/bash

THRESHOLD=80
LOG_FILE="/var/log/disk_alert.log"
DATE=$(date +"%d-%m-%Y %H:%M:%S")

# Get disk usage (excluding tmpfs & devtmpfs)
df -h | grep -Ev 'tmpfs|devtmpfs' | tail -n +2 | while read filesystem size used avail percent mount
do
    usage=$(echo "$percent" | tr -d '%')

    if [ "$usage" -gt "$THRESHOLD" ]; then
        echo "$DATE ALERT: Disk usage on $mount is ${usage}%" >> "$LOG_FILE"
    else
        echo "$DATE OK: Disk usage on $mount is ${usage}%" >> "$LOG_FILE"
    fi
done
