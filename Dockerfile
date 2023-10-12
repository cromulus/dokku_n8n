FROM n8nio/n8n:ai-beta
USER root

ENV PYTHONUNBUFFERED=1
RUN apk add --update --no-cache python3 && ln -sf python3 /usr/bin/python
RUN python3 -m ensurepip
USER node
RUN pip3 install --no-cache --upgrade pip setuptools wheel

RUN mkdir -p ~/.n8n/nodes && cd ~/.n8n/nodes && npm install n8n-nodes-carbonejs n8n-nodes-ldap n8n-nodes-chatwoot n8n-nodes-document-generator n8n-nodes-text-manipulation
ENV NODE_ENV=production
COPY requirements.txt /home/node
RUN pip3 install -r /home/node/requirements.txt
COPY setup.sh /
RUN /setup.sh
ENTRYPOINT []
EXPOSE 5678/tcp
