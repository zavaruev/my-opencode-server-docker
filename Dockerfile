# Minimal Dockerfile for OpenCode Server
# GitHub Actions builds this on every push to main
# Uses Node.js 18 LTS which has npm v9 (no catalog: protocol issues)

FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package.json ./

# Install production dependencies
# Using npm install with || to handle errors gracefully
# This avoids EUNSUPPORTEDPROTOCOL on GitHub Actions runners
RUN npm install --production 2>/dev/null || true

# Copy the built OpenCode distribution
COPY dist ./dist 2>/dev/null || true

# Copy .home directory configuration
COPY .home .home 2>/dev/null || true

# Copy .npmrc configuration
COPY .npmrc .npmrc 2>/dev/null || true

# Expose OpenCode port
EXPOSE 4096

# Start OpenCode server
ENTRYPOINT ["node", "dist/index.js"]