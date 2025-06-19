#!/usr/bin/env bash

set -euo pipefail
# NO NEED TO USE APP_NAME: dokku knows the app.

dokku storage:ensure-directory --chown heroku n8n_cache
dokku storage:ensure-directory n8n_system_cache

# Mount them to the correct locations
dokku storage:mount /var/lib/dokku/data/storage/n8n_cache:/home/node/.cache
dokku storage:mount /var/lib/dokku/data/storage/n8n_system_cache:/var/cache

dokku docker-options:add build "-v /var/lib/dokku/data/storage/n8n_cache:/home/node/.cache -v /var/lib/dokku/data/storage/n8n_system_cache:/var/cache"

# Restart the app so the mounts take effect
dokku ps:restart

