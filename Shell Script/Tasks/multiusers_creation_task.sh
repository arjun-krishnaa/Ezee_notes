#!/bin/bash

USERS=("ashok" "vimal" "vijay")

for USER in "${USERS[@]}"
do
    if ! id "$USER" &>/dev/null; then
        useradd -m -s /bin/bash "$USER"
        echo "$USER:Password@123" | chpasswd
        passwd -e "$USER"
        echo "User $USER created with temporary password"
    fi
done

-----------------------------------------------------------------------------

#!/bin/bash

LOGFILE="home/txt_files/user_creation.log"

# Username:UID:PrimaryGroup:ExtraGroups
USERS=(
"vivek:2001:dev:admin1"
"kiran:2002:dev:admin1"
"revanth:2003:dev:admin1"
)

echo "User creation started at $(date)" >> "$LOGFILE"

# Create primary group if not exists
if ! getent group dev >/dev/null; then
    groupadd dev
    echo "Group dev created" >> "$LOGFILE"
fi

for ENTRY in "${USERS[@]}"
do
    IFS=":" read -r USER UID PGRP EGRP <<< "$ENTRY"

    if id "$USER" &>/dev/null; then
        echo "User $USER already exists" >> "$LOGFILE"
        continue
    fi

    useradd -u "$UID" -g "$PGRP" -G "$EGRP" -m -s /bin/bash "$USER"

    echo "$USER:Temp@123" | chpasswd
    passwd -e "$USER"

    echo "User $USER created successfully" >> "$LOGFILE"
done

echo "User creation finished at $(date)" >> "$LOGFILE"
