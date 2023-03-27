FROM node:18-alpine

# Update everything and install needed dependencies
RUN apk add --update graphicsmagick tzdata git su-exec grep python3 py3-pip gcc make g++ zlib-dev portaudio portaudio-dev swig curl bash cmake boost-dev docker openrc ffmpeg chromium chromium-chromedriver gnu-libiconv

# # Set a custom user to not have n8n run as root
USER root

ARG N8N_VERSION=0.220.0
# Install n8n and the also temporary all the packages
# it needs to build it correctly.
RUN apk --update add --virtual build-dependencies python3 build-base build-dependencies ca-certificates && \
	npm config set python "$(which python3)" && \
	npm_config_user=root npm install -g full-icu n8n@$N8N_VERSION && \
	apk del build-dependencies \
	&& rm -rf /root /tmp/* /var/cache/apk/* && mkdir /root;

ENV NODE_FUNCTION_ALLOW_EXTERNAL=node-redis,great-circle-distance,lodash,jquery,libphonenumber-js,cryptojs
RUN npm_config_user=root npm install -g node-redis great-circle-distance lodash jquery libphonenumber-js cryptojs

# Install fonts
RUN apk --no-cache add --virtual fonts msttcorefonts-installer fontconfig && \
	update-ms-fonts && \
	fc-cache -f && \
	apk del fonts && \
	find  /usr/share/fonts/truetype/msttcorefonts/ -type l -exec unlink {} \; \
	&& rm -rf /root /tmp/* /var/cache/apk/* && mkdir /root
## these cause errors
# RUN cd /usr/local/lib/node_modules/n8n && npm install n8n-nodes-text-manipulation n8n-nodes-puppeteer-extended
ENV NODE_ICU_DATA /usr/local/lib/node_modules/full-icu
COPY . /
RUN /setup.sh

EXPOSE 5678/tcp
