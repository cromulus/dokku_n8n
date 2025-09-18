#!/bin/bash

# Script to install n8n node from Dokku storage at runtime
# This should be run as part of the container startup

STORAGE_PATH="/mnt/storage/reminders-api.tar.gz"
N8N_NODES_PATH="/home/node/.cache/n8n-nodes"

echo "Checking for storage file at $STORAGE_PATH..."

if [ -f "$STORAGE_PATH" ]; then
    echo "Found storage file, installing node..."
    
    # Ensure n8n-nodes directory exists
    mkdir -p "$N8N_NODES_PATH"
    
    # Install the node
    pnpm install --prefix "$N8N_NODES_PATH" "$STORAGE_PATH"
    
    if [ $? -eq 0 ]; then
        echo "✅ Successfully installed node from storage"
    else
        echo "❌ Failed to install node from storage"
    fi
else
    echo "Storage file not found, skipping node installation"
fi
