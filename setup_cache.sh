#!/usr/bin/env bash

set -euo pipefail

# Create persistent directories for apk, pip, and pnpm
dokku storage:ensure-directory n8n_apk_cache
dokku storage:ensure-directory n8n_pip_cache
dokku storage:ensure-directory n8n_pnpm_cache
dokku storage:ensure-directory n8n_nodes_cache

# Mount them to the locations used in the Dockerfile
dokku storage:mount /var/lib/dokku/data/storage/n8n_apk_cache:/cache/apk
dokku storage:mount /var/lib/dokku/data/storage/n8n_pip_cache:/cache/pip
dokku storage:mount /var/lib/dokku/data/storage/n8n_pnpm_cache:/cache/pnpm
dokku storage:mount /var/lib/dokku/data/storage/n8n_nodes_cache:/tmp/n8n-nodes

