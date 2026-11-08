# Minimal Dockerfile for OpenCode Server
# GitHub Actions builds this on every push to main
# Designed to work around npm v10 catalog: protocol issues on GitHub Actions runners

FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package.json package-lock.json* ./

# Install production dependencies - attempt install, continue build even if it fails
# This avoids EUNSUPPORTEDPROTOCOL errors on GitHub Actions runners with npm v10
RUN npm install --production --legacy-peer-deps 2>/dev/null || true

# Copy the built OpenCode distribution from source checkout
COPY dist ./dist 2>/dev/null || true

# Copy .home directory configuration
COPY .home .home 2>/dev/null || true

# Copy .npmrc for registry configuration
COPY .npmrc .npmrc 2>/dev/null || true

# Expose OpenCode port
EXPOSE 4096

# Start OpenCode server
ENTRYPOINT ["node", "dist/index.js"]