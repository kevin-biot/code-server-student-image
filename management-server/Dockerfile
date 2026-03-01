# Management Server - Multi-stage build
FROM node:20-slim AS deps
WORKDIR /app
COPY package.json ./
RUN npm install

FROM node:20-slim AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

FROM node:20-slim AS runner
WORKDIR /app
ENV NODE_ENV=production

# Copy standalone output
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

# Admin scripts and profiles are mounted as volumes at runtime:
#   -v ../profiles:/app/profiles
#   -v ../admin:/app/admin
#   -v ../deploy:/app/deploy
#   -v ../tests:/app/tests

EXPOSE 3000
ENV PORT=3000
ENV HOSTNAME=0.0.0.0

CMD ["node", "server.js"]
