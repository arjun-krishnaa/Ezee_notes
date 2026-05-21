#!/bin/bash

# Log file

LOG_FILE="/var/log/self_heal.log"

# Services to monitor

SERVICES=("nginx" "tomcat")

# Function to check and restart service

check_service() {
SERVICE=$1

```
systemctl is-active --quiet $SERVICE
if [ $? -ne 0 ]; then
    echo "$(date) - $SERVICE is DOWN. Restarting..." >> $LOG_FILE
    systemctl restart $SERVICE

    # Check if restart was successful
    systemctl is-active --quiet $SERVICE
    if [ $? -eq 0 ]; then
        echo "$(date) - $SERVICE restarted SUCCESSFULLY." >> $LOG_FILE
    else
        echo "$(date) - FAILED to restart $SERVICE!" >> $LOG_FILE
    fi
else
    echo "$(date) - $SERVICE is running." >> $LOG_FILE
fi
```

}

# Loop through services

for service in "${SERVICES[@]}"
do
check_service $service
done


#!/bin/bash

# Check if nginx is active
if systemctl is-active --quiet nginx; then
    echo "Nginx is active"
else
    echo "Nginx is not active"
    echo "Trying to start nginx..."

    if systemctl start nginx; then
        echo "Nginx started successfully"
    else
        echo "Unable to start nginx"
        exit 1
    fi
fi