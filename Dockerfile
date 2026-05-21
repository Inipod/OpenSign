FROM node:22.14.0

RUN apt-get update \
  && apt-get install -y libreoffice caddy \
  && rm -rf /var/lib/apt/lists/*

# ── Frontend (build) ──────────────────────────────────────────────────────────
WORKDIR /app/client

COPY apps/OpenSign/package*.json ./
RUN npm ci

COPY apps/OpenSign/ .

ENV NODE_ENV=production
ENV GENERATE_SOURCEMAP=false

RUN npm run build \
  && sed -i '/<head>/a\<script src="/env.js"></script>' build/index.html

# ── Backend ───────────────────────────────────────────────────────────────────
WORKDIR /app/server

COPY apps/OpenSignServer/package*.json ./
RUN npm ci --omit=dev

COPY apps/OpenSignServer/ .

# ── Gateway + startup ─────────────────────────────────────────────────────────
WORKDIR /app

COPY Caddyfile.railway Caddyfile
COPY scripts/railway-start.sh railway-start.sh
RUN chmod +x railway-start.sh

ENV NODE_ENV=production

EXPOSE 8080

CMD ["./railway-start.sh"]
