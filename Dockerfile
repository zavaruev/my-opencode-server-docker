# Dockerfile for OpenCode Server build
# Uses node:20 (debian-based) for better npm compatibility
# The image builds OpenCode from source and is pushed to GHCR via GitHub Actions

FROM node:20 AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    git \
    && rm -rf /var/lib/apt/lists/*

# Clone the OpenCode repository
RUN git clone --depth 1 https://github.com/anomalyco/opencode.git /app

# Install dependencies (may take a few minutes)
RUN npm install --legacy-peer-deps --no-package-lock

# Build OpenCode
RUN npm run build

# --- Final stage ---

FROM node:20-alpine

WORKDIR /app

# Install only runtime dependencies
RUN apk add --no-cache ca-certificates

# Copy built application from builder stage
COPY --from=builder /app/dist /app/dist
COPY --from=builder /app/package.json /app/package.json

# Install production dependencies only
RUN npm install --omit=dev

# Copy necessary files from builder for runtime
COPY --from=builder /app/.home /app/.home 2>/dev/null || true

EXPOSE 4096

ENTRYPOINT ["node", "dist/index.js"]