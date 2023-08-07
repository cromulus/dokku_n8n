#!/bin/sh
if [[ -z "${DB_POSTGRESDB_HOST}" ]]; then
DB_POSTGRESDB_USER=$(echo $DATABASE_URL | grep -oP "postgres://\K(.+?):" | cut -d: -f1)
DB_POSTGRESDB_PASSWORD=$(echo $DATABASE_URL | grep -oP "postgres://.*:\K(.+?)@" | cut -d@ -f1)
DB_POSTGRESDB_HOST=$(echo $DATABASE_URL | grep -oP "postgres://.*@\K(.+?):" | cut -d: -f1)
DB_POSTGRESDB_PORT=$(echo $DATABASE_URL | grep -oP "postgres://.*@.*:\K(\d+)/" | cut -d/ -f1)
DB_POSTGRESDB_DATABASE=$(echo $DATABASE_URL | grep -oP "postgres://.*@.*:.*/\K(.+?)$")
fi

if [[ -z "${QUEUE_BULL_REDIS_HOST}" ]]; then
# redis
QUEUE_BULL_REDIS_PASSWORD=$(echo $REDIS_URL | grep -oP "redis://.*:\K(.+?)@" | cut -d@ -f1)
QUEUE_BULL_REDIS_HOST=$(echo $REDIS_URL | grep -oP "redis://.*@\K(.+?):" | cut -d: -f1)
QUEUE_BULL_REDIS_PORT=$(echo $REDIS_URL | grep -oP "redis://.*@.*:\K(\d+)/" | cut -d/ -f1)
fi

# if [ -d /root/.n8n ] ; then
#   chmod o+rx /root
#   chown -R node /root/.n8n
#   ln -s /root/.n8n /home/node/
# fi

# chown -R node /home/node
