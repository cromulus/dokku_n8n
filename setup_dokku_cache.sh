#!/usr/bin/env bash

APP_NAME="n8n"  # Change this to your app name

# Ensure persistent directories exist
dokku storage:ensure-directory $APP_NAME /var/lib/dokku/data/storage/${APP_NAME}-apk-cache
dokku storage:ensure-directory $APP_NAME /var/lib/dokku/data/storage/${APP_NAME}-pip-cache

# Mount directories into app container (these paths must match the Dockerfile)
dokku storage:mount $APP_NAME /var/lib/dokku/data/storage/${APP_NAME}-apk-cache:/cache/apk
dokku storage:mount $APP_NAME /var/lib/dokku/data/storage/${APP_NAME}-pip-cache:/cache/pip

# Rebuild the app so cache takes effect
dokku ps:rebuild $APP_NAME
