#!/bin/bash

RPT="/home/report.txt"
DATE=$(TZ="Asia/Kolkata" date +"%d-%m-%y_%H-%M-%S")





touch "$RPT"

echo "-----------------------Today's [$DATE] System Health Report--------------------------------------"
echo "-----------------------Today's [$DATE] System Health Report--------------------------------------" >> "$RPT"
echo " "
echo " " >> "$RPT"
echo "-------------------------------------CPU usage Report--------------------------------------------" >> "$RPT"
echo "-------------------------------------CPU usage Report--------------------------------------------" 
echo " "
df -h >> "$RPT"
df -h
echo " "
echo " " >> "$RPT"
echo "------------------------------------Memory usage Report--------------------------------------------" >> "$RPT"
echo "------------------------------------Memory usage Report--------------------------------------------" 
echo " "
free -h >> "$RPT"
free -h
echo " "
echo " " >> "$RPT"
echo "-----------------------------------Running services Report------------------------------------------" >> "$RPT"
echo "-----------------------------------Running services Report------------------------------------------" 
echo " "
ps -ef >> "$RPT"
ps -ef
echo " "
echo " " >> "$RPT"



--------------------------------------------------------------------------------------------------------------------------

#!/bin/bash

# ===== Variables =====
DATE=$(date +"%d-%m-%Y %H:%M:%S")
HOSTNAME=$(hostname)
REPORT="/home/system_health_report.txt"
TO_EMAIL="wabide8868@naprb.com"     # CHANGE THIS
SUBJECT="System Health Report - $HOSTNAME - $DATE"

# ===== Report Header =====
echo "System Health Report" > "$REPORT"
echo "Hostname : $HOSTNAME" >> "$REPORT"
echo "Date     : $DATE" >> "$REPORT"
echo "===================================" >> "$REPORT"

# ===== CPU Usage =====
echo -e "\nCPU Usage:" >> "$REPORT"
top -bn1 | grep "Cpu(s)" >> "$REPORT"

# ===== Memory Usage =====
echo -e "\nMemory Usage:" >> "$REPORT"
free -h >> "$REPORT"

# ===== Disk Usage =====
echo -e "\nDisk Usage:" >> "$REPORT"
df -h >> "$REPORT"

# ===== Running Services =====
echo -e "\nRunning Services:" >> "$REPORT"
systemctl list-units --type=service --state=running >> "$REPORT"

# ===== Email the Report =====
mailx -s "$SUBJECT" "$TO_EMAIL" < "$REPORT"


