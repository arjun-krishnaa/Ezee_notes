#!/bin/bash
# not able to delete all user. 1st user will be deleted.
USER=("vivek" "revanth" "kiran")
LOG="/home/txt_files/user_creation.txt"



echo "users deletion started at $(date)" >> "$LOG"

if id "$USER" &>dev/null  ; then
    userdel -r "$USER"
    echo "user deletion was succesfull: deleted users $USERS" >> "$LOG"
  else
    echo "user deletion was failed" >> "$LOG"
    exit 0

fi
echo "given users $USERS were not found" >> "$LOG"

------------------------------------------------------------------------
# not able to delete all user. 1st user will be deleted.
#!/bin/bash

USERS=("vivek" "revanth" "kiran")
LOG="/home/txt_files/user_deletion.txt"
DATE=$(date)

mkdir -p /home/txt_files

echo "User deletion started at $DATE" >> "$LOG"

for USER in "${USERS[@]}"
do
    if id "$USER" &>/dev/null; then
        userdel -r "$USER"
        if [ $? -eq 0 ]; then
            echo "User $USER deleted successfully" >> "$LOG"
        else
            echo "Failed to delete user $USER" >> "$LOG"
        fi
    else
        echo "User $USER not found" >> "$LOG"
    fi
done

echo "User deletion completed at $(date)" >> "$LOG"
