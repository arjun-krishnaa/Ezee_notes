#!/bin/bash

# ===== Variables =====
SRC="/home/notes/notes/Notes"
DEST="/home/backup/data"
LOG_DIR="/home/backup"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FILE="$LOG_DIR/backup_$DATE.log"

# ===== Create required directories =====
mkdir -p "$DEST"
mkdir -p "$LOG_DIR"

# ===== Start Backup =====
echo "Incremental Backup Started at $(date)" >> "$LOG_FILE"
echo "Source      : $SRC" >> "$LOG_FILE"
echo "Destination : $DEST" >> "$LOG_FILE"
echo "-------------------------------------" >> "$LOG_FILE"

rsync -av --delete --itemize-changes "$SRC/" "$DEST/" >> "$LOG_FILE" 2>&1

# ===== End Backup =====
echo "-------------------------------------" >> "$LOG_FILE"
echo "Incremental Backup Completed at $(date)" >> "$LOG_FILE"
