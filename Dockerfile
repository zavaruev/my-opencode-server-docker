# Dockerfile for OpenCode Server - uses Node.js 18 LTS with npm v9
# Compatible with GitHub Actions runners

FROM node:18-alpine AS builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache python3 make g++ git \
    && rm -rf /var/lib/apt/lists/*

# Clone OpenCode repository
RUN git clone --depth 1 https://github.com/anomalyco/opencode.git /app

# Install dependencies with npm v9 (compatible with GitHub Actions)
RUN npm config set legacy-peer-deps true 2>/dev/null
RUN npm install

# Build OpenCode
RUN npm run build

# --- Final stage ---

FROM node:18-alpine

WORKDIR /app

RUN apk add --no-cache ca-certificates

# Copy built application
COPY --from=builder /app/dist /app/dist

# Install production dependencies
COPY --from=builder /app/package.json /app/package.json
RUN npm install --omit=dev

EXPOSE 4096

ENTRYPOINT ["node", "dist/index.js"]