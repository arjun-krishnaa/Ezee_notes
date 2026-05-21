#!/bin/bash

# -----------------------------
# CONFIGURATION
# -----------------------------
LOG_DIR="/var/log/nginx"
S3_BUCKET="s3://28-feb-demo/nginx-logss"
STATE_FILE="/var/tmp/nginx_s3_uploaded.state"
LOG_FILE="/var/log/nginx_s3_backup.log"

HOST=$(hostname)
DATE=$(date +%F)

echo "[$(date)] ===== Backup Started =====" >> $LOG_FILE

# -----------------------------
# FIND LAST 3 DAYS FILES
# -----------------------------
FILES=$(find $LOG_DIR -type f -name "access*.log*" -mtime -3)

if [ -z "$FILES" ]; then
    echo "[$(date)] No logs found for last 3 days" >> $LOG_FILE
    exit 0
fi

# -----------------------------
# PROCESS EACH FILE
# -----------------------------
for file in $FILES; do

    # Skip current active log
    if [[ "$file" == *"access.log" ]]; then
        continue
    fi

    # -------------------------
    # CHECK DUPLICATE UPLOAD
    # -------------------------
    grep -qx "$file" $STATE_FILE 2>/dev/null
    if [ $? -eq 0 ]; then
        continue
    fi

    # -------------------------
    # COMPRESS IF NOT .gz
    # -------------------------
    if [[ "$file" != *.gz ]]; then
        gzip "$file"
        if [ $? -ne 0 ]; then
            echo "[$(date)] ERROR: Compression failed for $file" >> $LOG_FILE
            continue
        fi
        file="$file.gz"
    fi

    # -------------------------
    # UPLOAD TO S3
    # -------------------------
    aws s3 cp "$file" "$S3_BUCKET/$HOST/$DATE/"

    if [ $? -eq 0 ]; then
        echo "$file" >> $STATE_FILE
        echo "[$(date)] SUCCESS: Uploaded $file" >> $LOG_FILE
    else
        echo "[$(date)] ERROR: Upload failed for $file" >> $LOG_FILE
    fi

done

echo "[$(date)] ===== Backup Completed =====" >> $LOG_FILE

exit 0


#!/bin/bash

while true
do
    echo "-----------------------------"
    echo "       System Menu"
    echo "-----------------------------"
    echo "1. Start nginx service"
    echo "2. Start tomcat service"
    echo "3. Check CPU Usage"
    echo "4. Exit"
    echo "-----------------------------"

    read -p "Enter your choice [1-4]: " choice

    case $choice in
        1)
            echo "check Nginx status:"
            systemctl is-active nginx
            echo "starting Nginx server"
            systemctl start nginx.service
            echo "check Nginx status:"
            systemctl is-active nginx
            ;;
        2)
            echo "check tomcat status:"
            systemctl is-active tomcat
            echo "starting tomcat server"
            systemctl start tomcat.service
            echo "check tomcat status:"
            systemctl is-active tomcat
            
            ;;
        3)
            echo "CPU Usage:"
            top -bn1 | grep "Cpu(s)"
            ;;
        4)
            echo "Exiting... Bye!"
            exit 0
            ;;
        *)
            echo "Invalid option. Please choose 1-4"
            ;;
    esac

    echo
    read -p "Press Enter to continue..."
done