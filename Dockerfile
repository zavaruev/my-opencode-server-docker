# OpenCode Server image
# Auto-built in GitHub Actions and pushed to ghcr.io/zavaruev/my-opencode-server-docker
# OPENCORE_VERSION is resolved by the workflow to the newest 2.x.x tag
# published by upstream (ghcr.io/anomalyco/opencode). :latest tracks the old
# 1.0.x line, so the version tag MUST be resolved explicitly.

ARG OPENCORE_VERSION=2.2.7
FROM ghcr.io/anomalyco/opencode:${OPENCORE_VERSION}

LABEL org.opencontainers.image.description="OpenCode Server (auto-built from upstream ${OPENCORE_VERSION})"

# Node.js нужен для локальных MCP-серверов, которые OpenCode запускает через npx
# (в частности github). Без него сервер горит красным: "ChildProcess.spawn npx ... not found".
RUN apk add --no-cache nodejs npm

EXPOSE 4096

# The base image ships the compiled `opencode` binary in /usr/local/bin
ENTRYPOINT ["opencode"]
CMD ["serve", "--hostname", "0.0.0.0", "--port", "4096"]
