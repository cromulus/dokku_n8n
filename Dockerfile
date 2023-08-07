ARG NODE_VERSION=18
FROM node:${NODE_VERSION}-alpine

WORKDIR /home/node
COPY .npmrc /usr/local/etc/npmrc

RUN \
	apk add --update git openssh graphicsmagick tini tzdata ca-certificates libc6-compat && \
	npm install -g npm@9.5.1 full-icu && \
	rm -rf /var/cache/apk/* /root/.npm /tmp/* && \
	# Install fonts
	apk --no-cache add --virtual fonts msttcorefonts-installer fontconfig && \
	update-ms-fonts && \
	fc-cache -f && \
	apk del fonts && \
	find  /usr/share/fonts/truetype/msttcorefonts/ -type l -exec unlink {} \; && \
	rm -rf /var/cache/apk/* /tmp/*

ENV NODE_ICU_DATA /usr/local/lib/node_modules/full-icu

ARG N8N_VERSION
RUN if [ -z "$N8N_VERSION" ] ; then echo "The N8N_VERSION argument is missing!" ; exit 1; fi

ENV N8N_VERSION=${N8N_VERSION}
ENV NODE_ENV=production
RUN set -eux; \
	apkArch="$(apk --print-arch)"; \
	case "$apkArch" in \
	'armv7') apk --no-cache add --virtual build-dependencies python3 build-base;; \
	esac && \
	npm install -g --omit=dev n8n@${N8N_VERSION} && \
	case "$apkArch" in \
	'armv7') apk del build-dependencies;; \
	esac && \
	find /usr/local/lib/node_modules/n8n -type f -name "*.ts" -o -name "*.js.map" -o -name "*.vue" | xargs rm && \
	rm -rf /root/.npm

USER root


COPY setup.sh /
RUN /setup.sh
ENTRYPOINT []
EXPOSE 5678/tcp
