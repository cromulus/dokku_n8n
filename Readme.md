# n8n on Dokku

A production-ready n8n setup running on Dokku with PostgreSQL, Redis, and custom community nodes.

## Architecture

This setup uses:
- **n8n** as the main workflow automation platform
- **PostgreSQL** for data persistence
- **Redis** for queue management (queue mode)
- **nginx** for load balancing and webhook routing
- **Custom community nodes** installed from local storage

The architecture follows the [recommended pattern for highly reliable n8n hosting](https://community.n8n.io/t/best-pattern-for-a-highly-reliable-aws-host/6848/4).

## Initial Setup

### 1. Create Dokku App
```bash
dokku apps:create n8n
```

### 2. Setup Database
```bash
# Create PostgreSQL database
dokku postgres:create n8n
dokku postgres:link n8n n8n

# Set database environment variables
dokku config:set n8n DB_TYPE=postgres DB_POSTGRES_DB=n8n DB_POSTGRES_USER=n8n DB_POSTGRES_PASSWORD=... DB_POSTGRES_HOST=... DB_POSTGRES_PORT=...
```

### 3. Setup Redis (Optional but recommended)
```bash
# Create Redis instance
dokku redis:create n8n
dokku redis:link n8n n8n

# Set Redis environment variables
dokku config:set n8n QUEUE_BULL_REDIS_DB=0 QUEUE_BULL_REDIS_HOST=... QUEUE_BULL_REDIS_PORT=... QUEUE_BULL_REDIS_PASSWORD=... QUEUE_BULL_REDIS_TLS=...
```

### 4. Configure Proxy
```bash
dokku proxy:ports-set n8n http:80:5678
```

### 5. Enable SSL
```bash
dokku letsencrypt:enable n8n
```

### 6. Set Execution Mode
```bash
dokku config:set n8n EXECUTIONS_MODE=queue EXECUTIONS_PROCESS=main
```

## Deployment

### Deploy to Dokku
```bash
git remote add dokku dokku@your-server.com:n8n
git push dokku main
```

### Environment Variables
The `setup.sh` script automatically converts standard environment variables into n8n-compatible format. See [n8n environment variables documentation](https://docs.n8n.io/hosting/environment-variables/).

## Updating n8n

Use the unified update script:

```bash
# Check for updates
./update-n8n.sh --check

# Update to latest version
./update-n8n.sh --latest

# Update to specific version
./update-n8n.sh --version 1.45.0

# Force rebuild current version
./update-n8n.sh --force

# Auto-update (checks and updates if new version available)
./update-n8n.sh
```

### Automated Updates
Set up a cron job for automatic updates:
```bash
# Add to crontab for daily updates at 2 AM
0 2 * * * /path/to/your/repo/update-n8n.sh >> /var/log/n8n-update.log 2>&1
```

## Custom Community Nodes

### Installing from Local Storage
Place your node tarball at `/mnt/storage/reminders-api.tar.gz` on your Dokku server. The container will automatically install it on startup.

### Adding New Dependencies
Add new JavaScript libraries in the `Dockerfile`:
```dockerfile
RUN pnpm install --prefix /home/node/.cache/n8n-nodes your-new-node
```

## File Structure

- `Dockerfile` - Main container configuration
- `setup.sh` - Environment variable setup script
- `update-n8n.sh` - Unified update script
- `install-storage-node.sh` - Runtime node installation
- `proxy/nginx.conf` - nginx configuration for load balancing
- `queue.nginx.conf.sigil` - nginx template for queue instances
- `queue.Procfile` - Process configuration for queue mode

## Important Notes

- **Don't run more than one main instance** - you'll get duplicate cron jobs
- The nginx configuration handles webhook routing to appropriate instances
- Community nodes are installed at runtime from mounted storage
- All updates are logged to `/var/log/n8n-update.log`

## Troubleshooting

### Check Logs
```bash
dokku logs n8n
```

### Restart Application
```bash
dokku ps:restart n8n
```

### Rebuild Application
```bash
dokku ps:rebuild n8n
```

### Check Storage Mount
```bash
dokku run n8n -- ls -la /mnt/storage/
```
