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
#
# RTK (Rust Token Killer) — CLI-прокси для плагина plugin-rtk_opencode-v2: переписывает
# shell-команды (git status -> rtk git status) и сжимает вывод до того, как его прочитает
# модель. Ставится статический musl-бинарь (образ на Alpine), только linux/amd64.
#
# ВАЖНО: не поднимать RTK_VERSION выше 1.1.0. Начиная с v1.2.0 бинарь собран под
# x86-64-v3 (AVX2) и падает SIGILL на хосте с Xeon X5670 (Westmere, без AVX).
# Перед bump-ом проверять на хосте: ./rtk --version && ./rtk rewrite "git status".
ARG RTK_VERSION=1.1.0
ARG RTK_SHA256=9454ad1b9489daa57ab0a9f4ebe2faaf4dc82b8a0f26c9e5135151abd7c9378d
RUN apk add --no-cache nodejs npm curl \
 && curl -fsSL "https://github.com/rtk-ai/rtk/releases/download/v${RTK_VERSION}/rtk-x86_64-unknown-linux-musl.tar.gz" -o /tmp/rtk.tar.gz \
 && echo "${RTK_SHA256}  /tmp/rtk.tar.gz" | sha256sum -c - \
 && tar -xzf /tmp/rtk.tar.gz -C /usr/local/bin rtk \
 && chmod +x /usr/local/bin/rtk \
 && rm -f /tmp/rtk.tar.gz \
 && rtk --version

EXPOSE 4096

# The base image ships the compiled `opencode` binary in /usr/local/bin
ENTRYPOINT ["opencode"]
CMD ["serve", "--hostname", "0.0.0.0", "--port", "4096"]
