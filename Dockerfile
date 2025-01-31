FROM n8nio/n8n:1.76.1

USER root

ENV PYTHONUNBUFFERED=1
RUN apk add --update --no-cache bash python3 curl && ln -sf python3 /usr/bin/python
RUN apk add --no-cache \
  chromium \
  chromium-chromedriver \
  nss \
  freetype \
  harfbuzz \
  ca-certificates \
  ttf-freefont \
  bind-tools \
  imagemagick

USER node
WORKDIR /home/node
RUN python3 -m venv .venv && \
 source .venv/bin/activate && \
 python3 -m ensurepip && \
 pip install --no-cache --upgrade pip && \
 pip install --no-cache --upgrade setuptools wheel tscribe search-engine-parser "search-engine-parser[cli]"

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser
ENV PYTHONUNBUFFERED=1
RUN npm install lodash pdf-parse filenamify-url @mozilla/readability jsdom aws-transcription-to-vtt puppeteer tweetnacl

RUN mkdir -p /tmp/n8n-nodes && cd /tmp/n8n-nodes && npm install n8n-nodes-carbonejs n8n-nodes-ldap n8n-nodes-chatwoot n8n-nodes-document-generator n8n-nodes-text-manipulation n8n-nodes-browser @digital-boss/n8n-nodes-google-pubsub n8n-nodes-logger n8n-nodes-advanced-flow n8n-nodes-webpage-content-extractor n8n-nodes-turndown-html-to-markdown n8n-nodes-keycloak n8n-nodes-globals n8n-nodes-rss-feed-trigger n8n-nodes-duckduckgo @n8n-zengchao/n8n-nodes-browserless n8n-nodes-puppeteer-extended @itustudentcouncil/n8n-nodes-basecamp n8n-nodes-twenty
ENV NODE_ENV=production
ENV N8N_CUSTOM_EXTENSIONS=/tmp/n8n-nodes
ENV NODE_FUNCTION_ALLOW_EXTERNAL=*
ENV NODE_FUNCTION_ALLOW_BUILTIN=*

COPY setup.sh /
RUN /setup.sh
ENTRYPOINT []
EXPOSE 5678/tcp
