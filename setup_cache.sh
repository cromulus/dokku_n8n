#!/usr/bin/env bash

set -euo pipefail
# NO NEED TO USE APP_NAME: dokku knows the app.

# Remove old incorrect mounts first (if they exist)
dokku storage:unmount /var/lib/dokku/data/storage/n8n_apk_cache:/cache/apk 2>/dev/null || true
dokku storage:unmount /var/lib/dokku/data/storage/n8n_pip_cache:/cache/pip 2>/dev/null || true
dokku storage:unmount /var/lib/dokku/data/storage/n8n_pnpm_cache:/cache/pnpm 2>/dev/null || true

# Create persistent directories for apk, pip, and pnpm
dokku storage:ensure-directory n8n_apk_cache
dokku storage:ensure-directory n8n_pip_cache
dokku storage:ensure-directory n8n_pnpm_cache
dokku storage:ensure-directory n8n_nodes_cache

# Mount them to the correct locations
dokku storage:mount /var/lib/dokku/data/storage/n8n_apk_cache:/var/cache/apk
dokku storage:mount /var/lib/dokku/data/storage/n8n_pip_cache:/home/node/.cache/pip
dokku storage:mount /var/lib/dokku/data/storage/n8n_pnpm_cache:/home/node/.cache/pnpm
dokku storage:mount /var/lib/dokku/data/storage/n8n_nodes_cache:/tmp/n8n-nodes

# Restart the app so the mounts take effect
dokku ps:restart

