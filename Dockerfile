# Minimal Dockerfile for OpenCode Server
# GitHub Actions builds this on every push to main
# Uses the official OpenCode binary - no npm install needed

FROM ghcr.io/anomalyco/opencode:2.2.6

# Apply label with build info for tracking
LABEL org.open-code.maintainer="zavaruev" \
      org.open-code.version="2.2.6"

# Expose OpenCode port
EXPOSE 4096

# Start OpenCode server using the pre-compiled binary
ENTRYPOINT ["opencode", "serve", "--hostname", "0.0.0.0", "--port", "4096"]