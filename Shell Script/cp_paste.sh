#!/bin/bash

SRC="/mnt/d/Arjun/Notes/*"
DEST=" /mnt/c/Users/admin/notes"

rm -rf "$DEST/*"

cp -r "$DEST" "$SRC"