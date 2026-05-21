#!/bin/bash

LOG_FILE="/var/log/git_auto_pull.log"

read -p "Enter Git repository URL: " GIT_URL
read -p "Enter branch (default: main): " BRANCH

BRANCH=${BRANCH:-main}
REPO_NAME=$(basename "$GIT_URL" .git)

echo "[$(date)] Starting operation for $GIT_URL" >> $LOG_FILE

if [ -d "$REPO_NAME" ]; then
    echo "Pulling latest code from $BRANCH..."

    cd "$REPO_NAME" || exit

    git checkout "$BRANCH"
    git pull origin "$BRANCH"

    if [ $? -eq 0 ]; then
        echo "[$(date)] SUCCESS: Pulled latest code" >> $LOG_FILE
    else
        echo "[$(date)] ERROR: Git pull failed" >> $LOG_FILE
    fi

else
    echo "Cloning repository (branch: $BRANCH)..."

    git clone -b "$BRANCH" "$GIT_URL"

    if [ $? -eq 0 ]; then
        echo "[$(date)] SUCCESS: Clone completed" >> $LOG_FILE
    else
        echo "[$(date)] ERROR: Git clone failed" >> $LOG_FILE
    fi
fi