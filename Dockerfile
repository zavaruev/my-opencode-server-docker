# Minimal Dockerfile for OpenCode Server
# Builds OpenCode from source with npm v10 compatibility

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

# Install dependencies (npm v10 compatible)
RUN npm install

# Build OpenCode
RUN npm run build

# --- Final stage ---

FROM node:20-alpine

WORKDIR /app

# Install runtime dependencies
RUN apk add --no-cache ca-certificates

# Copy built application from builder stage
COPY --from=builder /app/dist /app/dist

# Copy package.json and install production deps
COPY --from=builder /app/package.json /app/package.json
RUN npm install --omit=dev

# Copy .home directory if needed
COPY --from=builder /app/.home /app/.home 2>/dev/null || true

EXPOSE 4096

ENTRYPOINT ["node", "dist/index.js"]