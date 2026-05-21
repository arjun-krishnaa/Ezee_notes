#!/bin/bash

SRC=/mnt/d/Arjun/Notes
DEST=/mnt/c/Users/admin/notes

# Clean destination
rm -rf "$DEST"/*
mkdir -p "$DEST"

# Copy content
cp -r "$SRC"/* "$DEST"/

------------------------------------------

#!/bin/bash

SRC=/mnt/c/Users/admin/notes
DEST=/home/admin1/notes
DATE=$(TZ="Asia/Kolkata" date +"%d-%m-%y_%H-%M-%S")
REPO="https://github.com/arjun-krishnaa/Ezee_notes.git"

# Clean destination
rm -rf "$DEST"/*
mkdir -p "$DEST"

# Copy content
cp -r "$SRC"/* "$DEST"/

cd "$DEST"

git init

git add .

git commit -m "commited at $DATE"

git remote add origin "$REPO"

git push -f origin master

-----------------------------------------------------------

CHAT GPT 

#!/bin/bash

set -e

SRC="/mnt/c/Users/admin/notes"
DEST="/home/admin1/notes"
DATE=$(TZ="Asia/Kolkata" date +"%d-%m-%Y %H:%M:%S")
REPO="https://github.com/arjun-krishnaa/Ezee_notes.git"
BRANCH="main"

echo "📁 Syncing files..."

mkdir -p "$DEST"

rsync -av --delete "$SRC"/ "$DEST"/

cd "$DEST"

# Initialize git only once
if [ ! -d ".git" ]; then
    git init
    git branch -M "$BRANCH"
    git remote add origin "$REPO"
fi

git add .

# Commit only if changes exist
if ! git diff --cached --quiet; then
    git commit -m "Committed at $DATE"
    git push origin "$BRANCH"
    echo "✅ Push successful"
else
    echo "ℹ️ No changes to commit"
fi

-----------------------------------------------------

#!/bin/bash

set -e

SRC="/mnt/c/Users/admin/notes"
DEST="/home/admin1/notes"
DATE=$(TZ="Asia/Kolkata" date +"%d-%m-%Y %H:%M:%S")
REPO="https://github.com/arjun-krishnaa/Ezee_notes.git"

echo "📁 Syncing files..."

mkdir -p "$DEST"

rsync -av --delete "$SRC"/ "$DEST"/

cd "$DEST"

git init
git remote add origin "$REPO"

# Commit only if changes exist
if ! git diff --cached --quiet; then
    git commit -m "Committed at $DATE"
    git push origin "$BRANCH"
    echo "✅ Push successful"
else
    echo "ℹ️ No changes to commit"
fi