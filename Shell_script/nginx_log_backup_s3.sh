#!/bin/bash

# ==============================
# CONFIGURATION
# ==============================
LOG_DIR="/var/log/nginx"
ACCESS_LOG="access.log"
BACKUP_DIR="/tmp/nginx_backups"
DATE=$(date +"%Y-%m-%d")

S3_BUCKET="s3://your-bucket-name/nginx-logs"
AWS_PROFILE="default"   # optional, remove if not needed

ERROR_LOG="/var/log/nginx_backup_error.log"

# ==============================
# CREATE BACKUP DIRECTORY
# ==============================
mkdir -p "$BACKUP_DIR"

# ==============================
# BACKUP FILE NAME
# ==============================
BACKUP_FILE="$BACKUP_DIR/access-$DATE.log.gz"

# ==============================
# COPY & COMPRESS LOG
# ==============================
cp "$LOG_DIR/$ACCESS_LOG" "$BACKUP_DIR/access-$DATE.log"

if [ $? -ne 0 ]; then
    echo "$(date) - ERROR: Failed to copy access log" >> "$ERROR_LOG"
    exit 1
fi

gzip "$BACKUP_DIR/access-$DATE.log"

if [ $? -ne 0 ]; then
    echo "$(date) - ERROR: Failed to compress log" >> "$ERROR_LOG"
    exit 1
fi

# ==============================
# UPLOAD TO S3
# ==============================
aws s3 cp "$BACKUP_FILE" "$S3_BUCKET/" --profile "$AWS_PROFILE"

if [ $? -ne 0 ]; then
    echo "$(date) - ERROR: Failed to upload to S3" >> "$ERROR_LOG"
    exit 1
fi

# ==============================
# CLEAR ORIGINAL LOG (OPTIONAL)
# ==============================
truncate -s 0 "$LOG_DIR/$ACCESS_LOG"

if [ $? -ne 0 ]; then
    echo "$(date) - ERROR: Failed to truncate access log" >> "$ERROR_LOG"
    exit 1
fi

# ==============================
# CLEANUP LOCAL BACKUP
# ==============================
rm -f "$BACKUP_FILE"

if [ $? -ne 0 ]; then
    echo "$(date) - WARNING: Failed to delete local backup file" >> "$ERROR_LOG"
fi

echo "$(date) - SUCCESS: Backup completed" >> "$ERROR_LOG"
exit 0