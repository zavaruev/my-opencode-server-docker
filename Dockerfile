# Minimal Dockerfile for OpenCode Server
# GitHub Actions builds this on every push to main
# Keeps compatibility by avoiding npm v10 catalog: protocol issues

FROM node:18-alpine

WORKDIR /app

# Copy the built OpenCode distribution from the source checkout.
# GitHub Actions actions/checkout provides the repository source code.
# The dist/ directory should already exist from a previous build or COPY.
COPY dist ./dist 2>/dev/null || true

# Copy .home directory configuration
COPY .home .home 2>/dev/null || true

# Expose OpenCode port
EXPOSE 4096

# Start OpenCode server using the distributed entry point
ENTRYPOINT ["node", "dist/index.js"]