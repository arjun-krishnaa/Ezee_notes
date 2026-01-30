#!/bin/bash

IST_TIME=$(TZ="Asia/Kolkata" date +"%Y-%m-%d %H:%M:%S")

echo "Current date and time : $(IST_TIME)"
echo "----------------------------------------------------------------------------------"
echo "DISK USAGE"
echo "_"

df -h

echo "----------------------------------------------------------------------------------"
echo "MEMORY USAGE"
echo "_"
free -h

------------------------------------------------------

#!/bin/bash

IST_TIME=$(TZ="Asia/Kolkata" date +"%Y-%m-%d %H:%M:%S")
LOGFILE="/home/logfile.txt"

echo "Current date and time : $IST_TIME" >> $LOGFILE
echo "----------------------------------------------------------------------------------" >> $LOGFILE
echo "DISK USAGE" >> $LOGFILE
echo "_" >> $LOGFILE

echo "$(df -h)" >> $LOGFILE
#df -h

echo "----------------------------------------------------------------------------------" >> $LOGFILE
echo "MEMORY USAGE" >> $LOGFILE
echo "_" >> $LOGFILE
echo "$(free -h)" >> $LOGFILE

#free -h

