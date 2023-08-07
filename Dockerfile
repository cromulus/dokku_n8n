
FROM n8nio/n8n:latest
USER root
WORKDIR /home/node/packages/cli

COPY setup.sh /
RUN /setup.sh

EXPOSE 5678/tcp
