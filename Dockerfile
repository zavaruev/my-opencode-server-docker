# Dockerfile для сборки OpenCode Server
FROM node:20-alpine AS builder

WORKDIR /app

# Устанавливаем зависимости для сборки
RUN apk add --no-cache git python3 make g++

# Клонируем репозиторий OpenCode
RUN git clone --depth 1 https://github.com/anomalyco/opencode.git /app

# Устанавливаем зависимости и собираем
RUN npm install
RUN npm run build

# Финальный образ
FROM node:20-alpine

WORKDIR /app

# Устанавливаем runtime зависимости
RUN apk add --no-cache ca-certificates

# Копируем собранное приложение
COPY --from=builder /app /app

# Устанавливаем production зависимости
RUN npm install --omit=dev

EXPOSE 4096

ENTRYPOINT ["node", "dist/index.js"]
