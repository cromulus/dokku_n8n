#!/bin/bash
APP_NAME="n8n"

echo "Starting no-cache rebuild for $APP_NAME at $(date)" >> /var/log/dokku_rebuild.log

# Update CACHEBUST to force a no-cache rebuild.
dokku config:set $APP_NAME CACHEBUST=$(date +%s) >> /dev/null 2>&1

# Rebuild the app, redirecting all output to /dev/null.
dokku ps:rebuild $APP_NAME > /dev/null 2>&1

echo "Completed rebuild for $APP_NAME at $(date)" >> /var/log/dokku_rebuild.log

