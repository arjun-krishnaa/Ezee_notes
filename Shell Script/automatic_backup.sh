#!/bin/bash

SRC="/home/shell_script"
DEST="/home/shell_backup"
DATE=$(date +"%d-%m-%y_%H-%M-%S")
LOG="$DEST/backuplog.txt"
BACKUP_FILE="$DEST/docs_backup_$DATE.tar.gz"

# Create backup directory if not exists
mkdir -p "$DEST"

# Create log file if not exists
touch "$LOG"

# Log directory listing
ls -la "$SRC" >> "$LOG"

# Create tar backup
tar -cpzf "$BACKUP_FILE" "$SRC" >> "$LOG" 2>&1

# Log success message
echo "Backup completed successfully at $DATE" >> "$LOG"

--------------------------------------------------------------------------------

#!/bin/bash

SRC="/home/shell_script"
DEST="/home/shell_backup"
DATE=$(date + "%d-%m-%y_%H=%m-%S")
LOG="/home/shell_backup/backuplog.txt"

mkdir $DEST

touch $LOG

ls -la ~ $SRC >> $LOG

tar -cpzf ~ $DEST.docs.backup.gz ~ $SRC

cp ~ $DEST.docs.backup.gz ~ $DEST


------------------------------------------------------

