FROM node:22-bookworm-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends espeak-ng ffmpeg \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --chown=node:node server.js ./server.js
USER node
EXPOSE 5000
HEALTHCHECK --interval=10s --timeout=3s --start-period=10s --retries=3 \
 CMD node -e "fetch('http://127.0.0.1:5000/healthz').then(r => { if (!r.ok) process.exit(1); }).catch(() => process.exit(1));"
CMD ["node", "server.js"]