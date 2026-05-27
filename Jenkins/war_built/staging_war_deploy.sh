#!/bin/bash
set -euo pipefail

S3_PATH="$1"                                # WAR file path in S3
TOMCAT_PATH="/usr/tomcat/tomcat-11"    # Tomcat base path
#TOMCAT_PATH="/usr/tomcat/dev-tomcat"
#TOMCAT_PATH="/usr/tomcat/tomcat-11.0.10"
WAR_NAME="busservices.war"
CATALINA_OUT="${TOMCAT_PATH}/logs/catalina.out"

echo "📦 Deploying WAR from: $S3_PATH"
echo "🧼 Cleaning previous deployment..."


# Verify S3 object is accessible
if ! aws s3 ls "$S3_PATH" > /dev/null; then
    echo "❌ ERROR: WAR file not found in S3: $S3_PATH"
    exit 1
fi
# Stop services gracefully
echo "🛑 Stopping Nginx and Tomcat..."
sudo systemctl stop nginx.service || true
sudo systemctl stop tomcat.service || true
#sudo systemctl stop bits-tomcat.service || true
#sudo systemctl stop dev-tomcat.service
sleep 3


# Download WAR from S3
echo "⬇️ Downloading WAR file..."
aws s3 cp "$S3_PATH" "${TOMCAT_PATH}/webapps/${WAR_NAME}"
if [ $? -ne 0 ]; then
    echo "❌ ERROR: Failed to download WAR from S3"
    exit 1
fi


# Start Tomcat
echo "▶️ Starting Tomcat..."
sudo systemctl start tomcat.service
#sudo systemctl start bits-tomcat.service
#sudo systemctl start dev-tomcat.service
# Confirm catalina.out exists
if [ ! -f "$CATALINA_OUT" ]; then
    echo "❌ ERROR: Catalina log file not found at: $CATALINA_OUT"
    exit 1
fi

# Tail catalina.out and wait for startup confirmation
echo "⏳ Waiting for Tomcat startup log entry..."
timeout 25 bash -c '
tail -n 0 -F "'"$CATALINA_OUT"'" | while read line; do
    echo "$line"
    if echo "$line" | grep -qi "Server startup in"; then
        echo "✅ Tomcat started successfully"
        exit 0
    fi
done
'
STARTUP_STATUS=$?

if [ $STARTUP_STATUS -ne 0 ]; then
    echo "❌ ERROR: Tomcat failed to start or startup timed out"
    exit $STARTUP_STATUS
fi

# Restart Nginx
echo "🌐 Starting Nginx..."
sudo systemctl start nginx.service

echo "✅ Deployment completed successfully"
exit 0
