#!/bin/bash

USR="arjun"
LOG="/home/txt_files/user_task_log.txt"
USLOC="/etc/passwd"

touch $LOG

cat "$USLOC" | grep "$USR"  >> "$LOG"

if  cat "$USLOC" | grep "$USR"  ; then
    echo "user $USR already exit"
    exit 1
else
    useradd -u "$USR" -m -d /home/"$USR" -s /bin/bash
    exit 0

fi


-------------------------------------------------------------------------------------------
#!/bin/bash

USR="ashok"
USRID="1215"
LOG="/home/txt_files/user_task_log.txt"
USLOC="/etc/passwd"

touch $LOG

cat "$USLOC" | grep "$USR"  >> "$LOG"

if  cat "$USLOC" | grep "$USR"  ; then
    echo "user $USR already exit"
    exit 1
else
    useradd -u "$USRID" "$USR" -m -d /home/"$USR" -s /bin/bash
    echo "user $USR created and user id is $USRID"
    exit 0

fi


