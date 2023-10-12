FROM n8nio/n8n:ai-beta

ENV NODE_ENV=production
RUN apk update add python3 build-base
RUN mkdir -p ~/.n8n/nodes && cd ~/.n8n/nodes && npm install @n8n/n8n-nodes-langchain @n8n/chat n8n-nodes-carbonejs n8n-nodes-ldap n8n-nodes-chatwoot n8n-nodes-document-generator n8n-nodes-text-manipulation

COPY setup.sh /
RUN /setup.sh
ENTRYPOINT []
EXPOSE 5678/tcp
