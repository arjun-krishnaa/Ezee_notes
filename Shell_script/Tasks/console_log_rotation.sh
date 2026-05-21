#!/bin/bash


# console_log_rotation.sh
# Rotates a Java console log so that only today's log remains as 'console.out'.
# Yesterday's log is saved as 'console_out.YYYY-MM-DD.log.gz'.
# Usage: console_log_rotation.sh [log_dir] [log_file] [retention_days]
# Example: ./console_log_rotation.sh /var/log/chatcore console.out 7

LOG_DIR="${1:-/var/log/chatcore}"
LOG_FILE="${2:-console.out}"
RETENTION_DAYS="${3:-7}"
LOCKFILE="$LOG_DIR/.${LOG_FILE}.rotate.lock"

get_mtime() {
    local file="$1"
    if stat -c %Y "$file" >/dev/null 2>&1; then
        stat -c %Y "$file"
    elif stat -f %m "$file" >/dev/null 2>&1; then
        stat -f %m "$file"
    else
        echo "0"
    fi
}

format_date() {
    local epoch="$1"
    if date -d "@$epoch" +%Y-%m-%d >/dev/null 2>&1; then
        date -d "@$epoch" +%Y-%m-%d
    else
        date -r "$epoch" +%Y-%m-%d
    fi
}

exec 9>"$LOCKFILE" || exit 1
if command -v flock >/dev/null 2>&1; then
    flock -n 9 || { echo "Another rotation is running. Exiting."; exit 0; }
else
    if [ -e "$LOCKFILE.lock" ]; then
        echo "Another rotation appears to be running. Exiting."; exit 0
    fi
    touch "$LOCKFILE.lock"
fi

cleanup() {
    if command -v flock >/dev/null 2>&1; then
        flock -u 9 || true
    else
        rm -f "$LOCKFILE.lock" || true
    fi
    rm -f "$LOCKFILE" 2>/dev/null || true
}
trap cleanup EXIT

cd "$LOG_DIR" || { echo "Cannot cd to $LOG_DIR" >&2; exit 1; }

LOGPATH="$LOG_DIR/$LOG_FILE"
if [ ! -e "$LOGPATH" ]; then
    echo "No log file found at $LOGPATH — nothing to rotate." >&2
    exit 0
fi

mtime_epoch=$(get_mtime "$LOGPATH")
if [ "$mtime_epoch" -eq 0 ]; then
    echo "Unable to determine mtime for $LOGPATH" >&2
    exit 1
fi

file_date=$(format_date "$mtime_epoch")
today_date=$(date +%Y-%m-%d)

if [ "$file_date" = "$today_date" ]; then
    echo "Log file is for today ($today_date); no rotation performed."
    exit 0
fi

rotated_base="console_out.${file_date}.log"
rotated_path="$LOG_DIR/$rotated_base"

# Copy and compress (preserves Java writing by truncating original afterwards)
cp --preserve=mode,timestamps "$LOGPATH" "$rotated_path"
if [ -f "$rotated_path" ]; then
    gzip -9 "$rotated_path"
    echo "Rotated $LOGPATH -> ${rotated_base}.gz"
    : > "$LOGPATH"
    echo "Truncated $LOGPATH to continue collecting today's logs."
else
    echo "Failed to create rotated file $rotated_path" >&2
    exit 2
fi

# Remove old gz files beyond retention
find "$LOG_DIR" -name "console_out.*.log.gz" -mtime +"$RETENTION_DAYS" -print -delete || true

exit 0

# Rotate logs: .log → .log.DATE
for file in *.out; do
    [ -f "$file" ] || continue
    mv "$file" "$file.$DATE"
    gzip "$file.$DATE"
done

# Delete logs older than 1 day
find "$LOG_DIR" -name "*.gz" -mtime +$RETENTION_DAYS -delete
