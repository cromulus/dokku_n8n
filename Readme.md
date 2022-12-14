Right now, running on dokku because it is simple and great.

we're using nginx to proxy webhook requests to the webhook instances, and webhook test to the main instance.

Don't run more than one main instance: we'll get duplicate cron jobs.

To scale up, we're going to just get a beefier machine in the short run.

This is the way:
https://community.n8n.io/t/best-pattern-for-a-highly-reliable-aws-host/6848/4

Add new JS libraries in the Docker file.


setup.sh turns standard ENV variables into things N8N can use.
https://docs.n8n.io/hosting/environment-variables/

perhaps: https://www.andreffs.com/blog/setup-n8n-on-kubernetes/

How to Upgrade? i think force a rebuild
