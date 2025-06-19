#!/usr/bin/env bash

set -euo pipefail
# NO NEED TO USE APP_NAME: dokku knows the app.

# Remove old incorrect mounts first (if they exist)
dokku storage:unmount /var/lib/dokku/data/storage/n8n_apk_cache:/cache/apk 2>/dev/null || true
dokku storage:unmount /var/lib/dokku/data/storage/n8n_pip_cache:/cache/pip 2>/dev/null || true
dokku storage:unmount /var/lib/dokku/data/storage/n8n_pnpm_cache:/cache/pnpm 2>/dev/null || true

# Create persistent directories with correct ownership
# Using --chown root for system cache, --chown heroku (1000:1000) for node user cache
dokku storage:ensure-directory --chown root n8n_system_cache
dokku storage:ensure-directory --chown heroku n8n_node_cache

# Mount them to the correct locations
dokku storage:mount /var/lib/dokku/data/storage/n8n_system_cache:/var/cache
dokku storage:mount /var/lib/dokku/data/storage/n8n_node_cache:/home/node/.cache

# Restart the app so the mounts take effect
dokku ps:restart

