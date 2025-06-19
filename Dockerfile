ARG CACHEBUST=1
FROM n8nio/n8n:latest

USER root

ENV PYTHONUNBUFFERED=1
RUN ln -s /var/cache/apk /etc/apk/cache

RUN --mount=type=cache,target=/etc/apk/cache apk add --update-cache bash python3 curl \
  chromium \
  chromium-chromedriver \
  nss \
  freetype \
  harfbuzz \
  ca-certificates \
  ttf-freefont \
  bind-tools \
  imagemagick \
  build-base \
  python3-dev 

USER node
WORKDIR /home/node


RUN --mount=type=cache,target=/home/node/.venv,uid=1000,gid=1000 \
 --mount=type=cache,target=/home/node/.cache/pip,uid=1000,gid=1000 \
 python3  -m venv .venv && \
 source .venv/bin/activate && \
 python3 -m ensurepip && \
 pip install --upgrade pip && \
 pip install --upgrade setuptools wheel tscribe search-engine-parser gtfs-realtime-bindings pynacl nyct-gtfs "search-engine-parser[cli]"

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser
ENV PYTHONUNBUFFERED=1

RUN --mount=type=cache,target=/home/node/node_modules/,uid=1000,gid=1000 \
--mount=type=cache,target=/home/node/.cache/pnpm,uid=1000,gid=1000 \
pnpm install lodash pdf-parse filenamify-url @mozilla/readability jsdom aws-transcription-to-vtt puppeteer tweetnacl gtfs-realtime-bindings node-fetch

RUN mkdir -p /home/node/.cache/n8n-nodes
RUN --mount=type=cache,target=/home/node/.cache/n8n-nodes,uid=1000,gid=1000 pnpm install --prefix /home/node/.cache/n8n-nodes @itustudentcouncil/n8n-nodes-basecamp \
     @n8n-zengchao/n8n-nodes-browserless \
     n8n-nodes-advanced-flow \
     n8n-nodes-carbonejs \
     n8n-nodes-globals \
     n8n-nodes-logger \
     n8n-nodes-puppeteer-extended \
     n8n-nodes-text-manipulation \
     n8n-nodes-turndown-html-to-markdown \
     n8n-nodes-tweetnacl \
     github:cromulus/n8n-nodes-graphiti \
     github:cromulus/n8n-nodes-twenty \
     n8n-nodes-webpage-content-extractor \
     n8n-nodes-websockets-lite \
     n8n-nodes-browser

ENV NODE_ENV=production
ENV N8N_CUSTOM_EXTENSIONS=/home/node/.cache/n8n-nodes
ENV NODE_FUNCTION_ALLOW_EXTERNAL=*
ENV NODE_FUNCTION_ALLOW_BUILTIN=*

# getting the environment variables in the right format
COPY setup.sh /home/node/setup.sh
RUN /home/node/setup.sh
ENTRYPOINT []
EXPOSE 5678/tcp
