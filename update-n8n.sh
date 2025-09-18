#!/bin/bash
# Unified script to update n8n on Dokku
# This script handles both manual updates and automated rebuilds

set -e

# Configuration
APP_NAME="n8n"
DOKKU_HOST="dokku.thesolarium.io"
LOG_FILE="/var/log/n8n-update.log"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to check if we're using 'latest' tag
is_using_latest() {
    grep -q "FROM n8nio/n8n:latest" Dockerfile
}

# Function to get current n8n version from Dockerfile
get_current_version() {
    grep "FROM n8nio/n8n:" Dockerfile | cut -d':' -f2
}

# Function to check for new n8n version (only for specific versions, not 'latest')
check_new_version() {
    local current_version=$(get_current_version)
    
    if [ "$current_version" = "latest" ]; then
        return 1  # Don't check for updates when using 'latest'
    fi
    
    # Get latest version from Docker Hub
    local latest_version=$(curl -s https://hub.docker.com/v2/repositories/n8nio/n8n/tags | \
                          jq -r '.results[] | select(.name != "latest") | .name' | \
                          grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | \
                          sort -V | tail -1)
    
    if [ "$current_version" != "$latest_version" ]; then
        log_message "New n8n version available: $latest_version (current: $current_version)"
        return 0
    else
        log_message "n8n is up to date (version: $current_version)"
        return 1
    fi
}

# Function to force rebuild with no cache
force_rebuild() {
    log_message "Starting forced rebuild for $APP_NAME"
    
    # Add no-cache option temporarily
    dokku docker-options:add $APP_NAME build "--no-cache"
    
    # Update CACHEBUST to force rebuild
    sed -i '' "s/ARG CACHEBUST=.*/ARG CACHEBUST=$(date +%s)/" Dockerfile
    
    # Commit the CACHEBUST change
    git add Dockerfile
    git commit -m "Force rebuild - $(date '+%Y-%m-%d %H:%M:%S')" || true
    
    # Rebuild
    dokku ps:rebuild $APP_NAME
    
    # Remove no-cache option
    dokku docker-options:remove $APP_NAME build "--no-cache"
    
    log_message "Rebuild completed for $APP_NAME"
}

# Function to update to latest version
update_to_latest() {
    local current_version=$(get_current_version)
    
    if [ "$current_version" = "latest" ]; then
        log_message "Already using 'latest' tag, forcing rebuild"
        force_rebuild
        return
    fi
    
    log_message "Updating from $current_version to latest"
    
    # Update Dockerfile to use latest
    sed -i '' "s/FROM n8nio\/n8n:.*/FROM n8nio\/n8n:latest/" Dockerfile
    
    # Force rebuild
    force_rebuild
}

# Function to update to specific version
update_to_version() {
    local target_version="$1"
    local current_version=$(get_current_version)
    
    if [ "$current_version" = "$target_version" ]; then
        log_message "Already at version $target_version, forcing rebuild"
        force_rebuild
        return
    fi
    
    log_message "Updating from $current_version to $target_version"
    
    # Update Dockerfile to use specific version
    sed -i '' "s/FROM n8nio\/n8n:.*/FROM n8nio\/n8n:$target_version/" Dockerfile
    
    # Force rebuild
    force_rebuild
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --latest          Update to latest n8n version"
    echo "  --version VERSION Update to specific n8n version"
    echo "  --force           Force rebuild with current version"
    echo "  --check           Check for updates without updating"
    echo "  --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --latest                    # Update to latest version"
    echo "  $0 --version 1.45.0           # Update to specific version"
    echo "  $0 --force                     # Force rebuild current version"
    echo "  $0 --check                     # Check for updates"
    echo "  $0                             # Auto-update if new version available"
}

# Main execution
main() {
    log_message "Starting n8n update process"
    
    case "${1:-}" in
        --latest)
            update_to_latest
            ;;
        --version)
            if [ -z "${2:-}" ]; then
                echo "Error: Version required with --version option"
                show_usage
                exit 1
            fi
            update_to_version "$2"
            ;;
        --force)
            force_rebuild
            ;;
        --check)
            if check_new_version; then
                log_message "Update available - run without --check to update"
                exit 0
            else
                log_message "No updates available"
                exit 1
            fi
            ;;
        --help)
            show_usage
            exit 0
            ;;
        "")
            # Auto-update mode
            if is_using_latest; then
                log_message "Using 'latest' tag - forcing rebuild"
                force_rebuild
            elif check_new_version; then
                log_message "New version available - updating automatically"
                update_to_latest
            else
                log_message "No updates available"
            fi
            ;;
        *)
            echo "Error: Unknown option '$1'"
            show_usage
            exit 1
            ;;
    esac
    
    log_message "Update process completed"
}

# Run main function with all arguments
main "$@"