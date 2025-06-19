#!/usr/bin/env bash

set -euo pipefail
# NO NEED TO USE APP_NAME: dokku knows the app.

dokku storage:ensure-directory --chown heroku n8n_node_cache

# Mount them to the correct locations
dokku storage:mount /var/lib/dokku/data/storage/n8n_node_cache:/home/node/.cache

# Restart the app so the mounts take effect
dokku ps:restart

