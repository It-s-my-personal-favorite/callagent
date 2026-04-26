# syntax=docker/dockerfile:1
# Next.js 16 (App Router) — CallAgent Marketing-Site
# Build-Kontext: apps/marketing-site (z. B. docker build -f apps/marketing-site/Dockerfile apps/marketing-site)

ARG NODE_VERSION=22-alpine

# --- Abhängigkeiten (caching) ---
FROM node:${NODE_VERSION} AS deps
WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci

# --- Build ---
FROM node:${NODE_VERSION} AS builder
WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Build-Zeit: NEXT_PUBLIC_* in den Client-Bundle einbetten
ARG NEXT_PUBLIC_SITE_URL
ARG NEXT_PUBLIC_APP_URL
ARG NEXT_PUBLIC_SUPPORT_EMAIL
ARG NEXT_PUBLIC_HELP_PHONE
ARG NEXT_PUBLIC_HELP_PHONE_TEL
ARG NEXT_PUBLIC_HELP_HOURS
ARG CALLAGENT_APP_UPSTREAM
ARG CALLAGENT_APP_PROXY_HOST
ENV NEXT_PUBLIC_SITE_URL=$NEXT_PUBLIC_SITE_URL \
    NEXT_PUBLIC_APP_URL=$NEXT_PUBLIC_APP_URL \
    NEXT_PUBLIC_SUPPORT_EMAIL=$NEXT_PUBLIC_SUPPORT_EMAIL \
    NEXT_PUBLIC_HELP_PHONE=$NEXT_PUBLIC_HELP_PHONE \
    NEXT_PUBLIC_HELP_PHONE_TEL=$NEXT_PUBLIC_HELP_PHONE_TEL \
    NEXT_PUBLIC_HELP_HOURS=$NEXT_PUBLIC_HELP_HOURS \
    CALLAGENT_APP_UPSTREAM=$CALLAGENT_APP_UPSTREAM \
    CALLAGENT_APP_PROXY_HOST=$CALLAGENT_APP_PROXY_HOST

ENV NEXT_TELEMETRY_DISABLED=1
RUN npm run build

# --- Laufzeit (klein) ---
FROM node:${NODE_VERSION} AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
# In Containern auf allen Schnittstellen lauschen
ENV HOSTNAME=0.0.0.0
ENV PORT=3000

RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public

# Rechte: standalone enthält server.js
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

CMD ["node", "server.js"]
