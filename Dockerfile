FROM n8nio/n8n:ai-beta
USER root

ENV PYTHONUNBUFFERED=1
RUN apk add --update --no-cache bash python3 && ln -sf python3 /usr/bin/python
RUN python3 -m ensurepip
RUN apk add --no-cache \
  	chromium \
  nss \
  freetype \
  harfbuzz \
  ca-certificates \
  ttf-freefont
USER node
RUN pip3 install --no-cache --upgrade pip setuptools wheel
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser
ENV PYTHONUNBUFFERED=1
RUN npm install lodash
RUN mkdir -p /tmp/n8n-nodes && cd /tmp/n8n-nodes && npm install n8n-nodes-carbonejs n8n-nodes-ldap n8n-nodes-chatwoot n8n-nodes-document-generator n8n-nodes-text-manipulation n8n-nodes-browser
ENV NODE_ENV=production
ENV N8N_CUSTOM_EXTENSIONS=/tmp/n8n-nodes
COPY requirements.txt /home/node
RUN pip3 install -r /home/node/requirements.txt
COPY setup.sh /
RUN /setup.sh
ENTRYPOINT []
EXPOSE 5678/tcp
