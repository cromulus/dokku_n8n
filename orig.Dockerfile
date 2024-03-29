FROM node:18-alpine

# Update everything and install needed dependencies
# some are needed to build n8n and some are stuff I want to run on the commandline.
RUN apk add --update graphicsmagick tzdata git su-exec grep python3 py3-pip gcc make g++ zlib-dev portaudio portaudio-dev swig curl bash cmake boost-dev docker openrc ffmpeg chromium chromium-chromedriver gnu-libiconv pn httpie redis

# # Set a custom user to not have n8n run as root


ARG N8N_VERSION=0.236.2
 # always install the latest
# Install n8n and the also temporary all the packages
# it needs to build it correctly.
RUN apk --update add --virtual build-dependencies python3 build-base build-dependencies ca-certificates && \
	npm config set python "$(which python3)" && \
	npm_config_user=root npm install -g full-icu n8n@$N8N_VERSION && \
	apk del build-dependencies \
	&& rm -rf /root /tmp/* /var/cache/apk/* && mkdir /root;

ENV NODE_FUNCTION_ALLOW_EXTERNAL=node-redis,great-circle-distance,lodash,jquery,cryptojs,moment

RUN npm_config_user=root npm install -g node-redis great-circle-distance lodash jquery cryptojs moment

# Install fonts
RUN apk --no-cache add --virtual fonts msttcorefonts-installer fontconfig && \
	update-ms-fonts && \
	fc-cache -f && \
	apk del fonts && \
	find  /usr/share/fonts/truetype/msttcorefonts/ -type l -exec unlink {} \; \
	&& rm -rf /root /tmp/* /var/cache/apk/* && mkdir /root
## these cause errors
#RUN cd /usr/local/lib/node_modules/n8n && npm install n8n-nodes-browserless
ENV NODE_ICU_DATA /usr/local/lib/node_modules/full-icu
USER node
COPY . /
RUN /setup.sh

EXPOSE 5678/tcp
