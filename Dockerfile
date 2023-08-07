
FROM n8nio/n8n:latest
USER root


COPY setup.sh /
RUN /setup.sh

WORKDIR /home/node/packages/cli

EXPOSE 5678/tcp
