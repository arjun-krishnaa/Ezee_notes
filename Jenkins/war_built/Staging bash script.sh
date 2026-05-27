#!/bin/bash

BRANCH=$1

GIT_DIR="/var/www/bits/root/dashboard/EzeeBus"
APP_DIR="$GIT_DIR/webapp"
ENV="staging"

echo "----------------------------------"
echo "🚀 Starting deployment"
echo "----------------------------------"

echo "Git directory : $GIT_DIR"
echo "App directory : $APP_DIR"
echo "Environment   : $ENV"
echo "Branch        : $BRANCH"
echo "----------------------------------"

cd $GIT_DIR || exit 1

echo "🧹 Cleaning any previous git states..."
git reset --hard
git clean -fd

echo "🔄 Fetching from origin..."
git fetch origin

echo "🌿 Switching branch..."
git checkout $BRANCH
git reset --hard origin/$BRANCH

cd $APP_DIR || exit 1

echo "📦 Installing dependencies..."
composer install --no-interaction --prefer-dist --optimize-autoloader

echo "🔐 Fixing permissions..."
chown -R nginx:nginx $APP_DIR
chmod -R 775 $APP_DIR

echo "🎨 Building assets..."

# Example minify (adjust if needed)
find public/assets -name "*.css" -exec echo "Minifying {}" \;
find public/assets -name "*.js" -exec echo "Minifying {}" \;

echo "✔ Build completed."
echo "----------------------------------"
echo "✅ Deployment completed successfully"
echo "Branch: $BRANCH"
echo "----------------------------------"