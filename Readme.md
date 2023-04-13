Right now, running on dokku because it is simple and great.

I use nginx.conf.sigil to setup webhook requests to go to the webhook instances, and webhook test to the main instance.

Don't run more than one main instance: we'll get duplicate cron jobs.

This is the way:
https://community.n8n.io/t/best-pattern-for-a-highly-reliable-aws-host/6848/4

Add new JS libraries in the Docker file.

setup.sh turns standard ENV variables into things N8N can use.
https://docs.n8n.io/hosting/environment-variables/

perhaps: https://www.andreffs.com/blog/setup-n8n-on-kubernetes/

How to Upgrade? Force a rebuild

How to dokku?
`dokku apps:create n8n`
You have to create a postgresql db and link it:
`dokku postgres:create n8n && dokku postgres:link n8n n8n`
then split up the database url into component parts for the envionment variables:
https://docs.n8n.io/hosting/environment-variables/environment-variables/
https://docs.n8n.io/hosting/supported-databases-settings/
`dokku config:set n8n DB_TYPE=postgres DB_POSTGRES_DB=n8n DB_POSTGRES_USER=n8n DB_POSTGRES_PASSWORD=... DB_POSTGRES_HOST=... DB_POSTGRES_PORT=...`

same for redis (we're doing queue mode for n8n, don't have to, but it's nicer)
`dokku redis:create n8n && dokku redis:link n8n n8n`
`dokku config:set n8n QUEUE_BULL_REDIS_DB=0 QUEUE_BULL_REDIS_HOST=... QUEUE_BULL_REDIS_PORT=... QUEUE_BULL_REDIS_PASSWORD=... QUEUE_BULL_REDIS_TLS=...` # etc.

set the proxy right:
`dokku proxy:ports-set n8n http:80:5678`

do letsencrypt:
`dokku letsencrypt:enable n8n`

I use these env variables: fast, but background process. YMMV
EXECUTIONS_MODE: queue
EXECUTIONS_PROCESS: main

the nginx.conf.sigil handles the proxying to the webhook instances.

Caddy is usefull if you want to run on something that doesn't handle mono-repos with multiple processes well.
