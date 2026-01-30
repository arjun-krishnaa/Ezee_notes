#!/bin/bash
SRC="/home/shell_script"
LOG="/home/txt_files/file_monit.log"

touch "$LOG"

if find "$SRC" -type f -time -1 ; then
    echo "new files were found"
else
    echo "news files not found"
fi

find "$SRC" -type f -time -1 >> "$LOG"

-------------------------------------------------------------------

#!/bin/bash

SRC="/home/shell_script"
LOG="/home/txt_files/file_monit.log"
DATE=$(date +"%d-%m-%Y %H:%M:%S")

touch "$LOG"

# Find files modified in the last 24 hours
FILES=$(find "$SRC" -type f -mtime -1)

if [ -n "$FILES" ]; then
    echo "$DATE : New files found:" >> "$LOG"
    echo "$FILES" >> "$LOG"
else
    echo "$DATE : No new files found" >> "$LOG"
fi
