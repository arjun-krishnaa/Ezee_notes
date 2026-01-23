#!/bin/bash

SERVICE="tomcat"
LOG="/home/txt_files/tomcat_service_check.log"
DATE=$(date +"%d-%m-%Y %H:%M:%S")

touch "$LOG"

if systemctl is-active --quiet "$SERVICE"; then
    echo "$DATE : Tomcat is already running" >> "$LOG"
else
    echo "$DATE : Tomcat is not running. Starting service..." >> "$LOG"

    cd /opt/tomcat/bin
    chmod 700 *
    ./startup.sh   >> "$LOG"
    systemctl status "$SERVICE"    >> "$LOG"
    
    #systemctl daemon-reload
    #systemctl start "$SERVICE"
    #systemctl enable "$SERVICE"

    if systemctl is-active --quiet "$SERVICE"; then
        echo "$DATE : Tomcat started successfully" >> "$LOG"
    else
        echo "$DATE : FAILED to start Tomcat" >> "$LOG"
    fi
fi


------------------------------------------------------------

#!/bin/bash

SERVICE="nginx"
DATE=$(date +"%d-%m-%Y %H:%M:%S")
LOG="/var/log/nginx_service_check.log"

# Ensure log file exists
touch "$LOG"

# Check service status
if systemctl is-active --quiet "$SERVICE"; then
    echo "$DATE : $SERVICE is already running" >> "$LOG"
else
    echo "$DATE : $SERVICE is not running. Attempting restart..." >> "$LOG"

    systemctl restart "$SERVICE"

    if systemctl is-active --quiet "$SERVICE"; then
        echo "$DATE : $SERVICE restarted successfully" >> "$LOG"
    else
        echo "$DATE : FAILED to restart $SERVICE" >> "$LOG"
    fi
fi
