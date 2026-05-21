#!/bin/bash

# Prompt for Git URL
read -p "Enter Git repository URL: " GIT_URL

# Extract repo name
REPO_NAME=$(basename "$GIT_URL" .git)

# Check if directory exists
if [ -d "$REPO_NAME" ]; then
    echo "Directory exists. Pulling latest code..."

    cd "$REPO_NAME" || exit

    git pull

    if [ $? -eq 0 ]; then
        echo "SUCCESS: Code updated"
    else
        echo "ERROR: Git pull failed"
    fi

else
    echo "Cloning repository..."

    git clone "$GIT_URL"

    if [ $? -eq 0 ]; then
        echo "SUCCESS: Repository cloned"
    else
        echo "ERROR: Git clone failed"
    fi
fi
