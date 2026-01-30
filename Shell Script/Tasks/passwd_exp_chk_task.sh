#!/bin/bash

DAYS=7
TODAY=$(date +%s)

echo "Users whose passwords expire within next $DAYS days:"
echo "----------------------------------------------------"

for USER in $(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd)
do
    EXPIRY_DATE=$(chage -l "$USER" 2>/dev/null | grep "Password expires" | cut -d: -f2 | xargs)

    if [[ "$EXPIRY_DATE" != "never" && -n "$EXPIRY_DATE" ]]; then
        EXPIRY_SECONDS=$(date -d "$EXPIRY_DATE" +%s)
        DAYS_LEFT=$(( (EXPIRY_SECONDS - TODAY) / 86400 ))

        if [[ $DAYS_LEFT -le $DAYS && $DAYS_LEFT -ge 0 ]]; then
            echo "User: $USER | Expires in: $DAYS_LEFT days | Expiry Date: $EXPIRY_DATE"
        fi
    fi
done
