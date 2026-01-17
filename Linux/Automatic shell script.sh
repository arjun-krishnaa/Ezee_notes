#!/bin/bash
SRC="/home/notes"
DES="/home"
LOG="/home/log.txt"
TIME=$(date +"%d-%m-%y_%H-%M-%S")

# Find files named "checklist" under $SRC
find "$SRC" -name "checklist"

# Append log entries with timestamp
echo "process start $TIME" >> "$LOG"
echo "process end $TIME" >> "$LOG"
