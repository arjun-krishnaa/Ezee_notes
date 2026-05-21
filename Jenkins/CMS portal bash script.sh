#!/bin/bash

set -e  # Exit on error

echo "===== CMS Portal Update Started ====="

APP_DIR="/var/www/cms-bus"   # change to your project path
BRANCH="release"

cd $APP_DIR

echo "Current directory: $(pwd)"

# Ensure git repo exists
if [ ! -d ".git" ]; then
  echo "❌ Not a git repository"
  exit 1
fi

# Fetch latest
echo "Fetching latest code..."
git fetch origin

# Checkout branch
echo "Checking out branch: $BRANCH"
git checkout $BRANCH

# Pull latest changes
echo "Pulling latest changes..."
git pull origin $BRANCH

# Optional: composer install
if [ -f "composer.json" ]; then
  echo "Running composer install..."
  composer install --no-dev --optimize-autoloader
fi

# Optional: permissions
echo "Setting permissions..."
chown -R www-data:www-data $APP_DIR

echo "===== CMS Portal Update Completed ====="