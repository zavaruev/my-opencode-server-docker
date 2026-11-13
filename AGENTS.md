# AGENTS.md

Репозиторий содержит только Docker Compose-сборку OpenCode Server. Исходного кода, сборки, тестов и git-истории здесь нет. В корне должен оставаться только `docker-compose.yml` — всё остательное (`.env`, конфиг, кэш) выносится за пределы репозитория или игнорируется.

## Запуск сервера

Выполнять из этой директории:

- `docker compose up -d` — старт контейнера
- `docker compose down` — остановка и удаление
- `docker compose ps` — статус
- `docker compose logs -f opencode-server` — логи
- `docker compose restart opencode-server` — применить изменения конфига
- `docker compose pull && docker compose up -d` — обновить образ до последней версии (через автосборку)

Сервер доступен на `http://localhost:4097` (порт из `.env`, внутри контейнера слушает 4096).

### ⚠️ Приоритет переменных: shell-окружение перекрывает `.env`

Compose при подстановке `${VAR}` сначала берёт значение из окружения процесса запуска и только потом из `.env`. Сессии агентов запускаются из host-процесса opencode, в окружении которого может висеть устаревший `OPENCODE_SERVER_PASSWORD` (креденшал для подключения к серверу) — из-за этого при `docker compose up -d` в контейнер попадал старый пароль вместо значения из `.env` («херня с паролями»).

Поэтому в `docker-compose.yml` все секреты и ключи передаются через `env_file: .env` — значения env_file shell-окружением НЕ перекрываются. Через `${}` интерполируются только нечувствительные вещи: `image`, `ports`, `user`, `group_add`. **Не возвращайте секреты в `environment` через `${}`.**

Проверка после пересоздания контейнера:

```bash
curl -u "opencode:<пароль из .env>" http://localhost:4097/api/info   # должно быть 200
```

Авторизация сервера — HTTP Basic (user `opencode`), пароль — ровно значение `OPENCODE_SERVER_PASSWORD` из `.env`. Файл `.home/.config/opencode/service.json` может содержать пароль старого инстанса — при локальном сервере он не используется и на авторизацию контейнерного сервера не влияет.

## Переменные окружения (`.env`)

Редактировать `.env`, не `docker-compose.yml`. Ключевые переменные:

- `UID`/`GID` — пользователь контейнера (`1000:1000`)
- `DOCKER_GID` — группа docker внутри контейнера для доступа к сокету (`971`)
- `OPENCODE_SERVER_PASSWORD` — пароль к серверу
- `OPENROUTER_API_KEY` / `ANTHROPIC_API_KEY` / `GEMINI_API_KEY` / `OPENAI_API_KEY` — ключи LLM-провайдеров
- `OPENCODE_SERVER_PORT` / `OPENCODE_SERVER_HOST` — хост-порт и адрес (`4097` / `0.0.0.0`)
- `WORKSPACE_DIR` — хост-каталог, монтируемый в `/workspace` для индексации проектов (`/mnt/media/projects`)
- `CPU_LIMIT` / `MEM_LIMIT` — ориентиры ресурсов (не применяются compose автоматически)
- `GITHUB_USERNAME` — ваш GitHub логин для автосборки образа

`.env` содержит реальные секреты. Файл добавлен в `.gitignore` — не коммитить. Реальные значения лучше хранить вне рабочей папки и подключать через `--env-file` или экспорт переменных при запуске.

## MCP-серверы

Конфиг лежит в `.home/.config/opencode/opencode.json` (монтируется как `/home/node/.config/opencode/opencode.json`).

Формат для OpenCode 2.2.5:

```json
{
  "mcp": {
    "servers": {
      "<имя>": {
        "type": "local",
        "command": ["npx", "-y", "<пакет>"],
        "enabled": true
      },
      "<имя>": {
        "type": "remote",
        "url": "https://...",
        "enabled": true,
        "headers": { "Authorization": "Bearer {env:TOKEN}" }
      }
    }
  }
}
```

### ⚠️ Важное ограничение этого контейнера

В образе `ghcr.io/anomalyco/opencode:2.2.5` **нет Node.js / npm / npx** внутри контейнера. Поэтому все локальные MCP-серверы, которые запускаются через `npx -y <пакет>`, **не будут работать** — они падают сразу после запуска и показываются красными в интерфейсе OpenCode.

Кроме того, OpenCode поддерживает только **`https://`** для удалённых MCP-серверов (`http://` отбрасывается). Локальные серверы на хосте нужно выставить через nginx-proxy-manager с HTTPS.

## Список MCP-серверов

| Сервер | Тип | URL | Статус |
|--------|-----|-----|--------|
| `context7` | remote | `https://context7.zavaruev.duckdns.org/mcp` | ✅ Работает (через NPM) |
| `search` | remote | `https://search.zavaruev.duckdns.org/mcp` | ✅ Работает (через NPM) |
| `github` | remote | `https://github.zavaruev.duckdns.org/mcp` | ✅ Работает (через NPM) |
| `hindsight` | remote | `https://hindsight.zavaruev.duckdns.org/mcp` | ✅ Работает (через NPM) |
| `npm-mcp` | remote | `http://host.docker.internal:8000/mcp` | ✅ Работает (управление NPM) |
| `sentry` | remote | `https://mcp.sentry.dev/mcp` | Требует Sign in |
| `linear` | remote | `https://mcp.linear.app/mcp` | Требует Sign in |

В `docker-compose.yml` добавлено `extra_hosts: ["host.docker.internal:host-gateway"]` и DNS `192.168.22.1`.

Локальные серверы, которые **убраны из конфига** (не работают без Node.js в контейнере):

- `filesystem` — `npx -y @modelcontextprotocol/server-filesystem /workspace`
- `playwright` — `npx -y @playwright/mcp@latest`
- `puppeteer` — `npx -y @modelcontextprotocol/server-puppeteer`
- `fetch` — `npx -y mcp-fetch-server`
- `git` — `npx -y @cyanheads/git-mcp-server`

Удалённые серверы, которые **убраны из конфига** (не работают с OpenCode):

- `grep` — `https://mcp.grep.app` — сервер не отвечает на MCP endpoints (все запросы возвращают 404/405/406)

Все 5 настроенных серверов (context7, search, github, hindsight, npm-mcp) работают через nginx-proxy-manager с SSL сертификатами. Прокси-хосты созданы через `npm-mcp` инструмент.

## Настройка серверов через nginx-proxy-manager (NPM)

Все серверы запущены на хосте и доступны через NPM с HTTPS:

| Сервер | Порт на хосте | Домен |
|--------|--------------|-------|
| `context7` | 8011 | `context7.zavaruev.duckdns.org` |
| `search` | 8013 | `search.zavaruev.duckdns.org` |
| `github` | 8014 | `github.zavaruev.duckdns.org` |
| `hindsight` | 8888 | `hindsight.zavaruev.duckdns.org` |
| `npm-mcp` | 8000 | `npm-mcp.zavaruev.duckdns.org` (нужен прокси) |

В админке NPM (`http://<хост>:81`):
1. **Proxy Hosts → Add Proxy Host**:
   - Domain Names: `<сервер>.zavaruev.duckdns.org`
   - Scheme: `http`
   - Hostname: `host.docker.internal`
   - Port: `<порт сервера>`
   - Websockets Support: **включить**
   - SSL: запросить новый Let's Encrypt сертификат
2. Сохранить. Подождать выпуск сертификата.

## Проверка серверов

Чтобы проверить, что инструменты видны в OpenCode:
1. Откройте интерфейс OpenCode (`http://localhost:4097`)
2. Наберите `/mcp` — серверы должны показывать статус `connected`
3. В чате попробуйте запросить поиск/воспоминание — модель предложит соответствующие инструменты

Если сервер красный — создайте прокси-хост в NPM для соответствующего порта и перезапустите `docker compose restart opencode-server`.

После изменения конфига обязательно `docker compose restart opencode-server`. Проверить работу серверов можно командой `/mcp` внутри OpenCode или по логам контейнера — ошибки `malformed` означают неверный формат.

## Oh My OpenCode

Установлен и настроен в `.home/.config/opencode/opencode.json` (секция `"plugins": ["oh-my-opencode@latest", "plugin-rtk_opencode-v2"]`) и `.home/.config/opencode/oh-my-opencode.json` (ростер агентов, категории задач, права доступа).

**Агенты:** oracle, librarian, explore
**Категории:** quick, visual-engineering, code

## RTK-плагин (экономия токенов)

В конфиге подключён плагин `plugin-rtk_opencode-v2` — перед выполнением shell-команд переписывает их в `rtk ...` (например, `git status` → `rtk git status`), и RTK сжимает вывод до того, как его прочитает модель. Требует бинарник `rtk` внутри контейнера — ставится в Dockerfile из релиза [rtk-ai/rtk](https://github.com/rtk-ai/rtk) (переменная `RTK_VERSION`).

**Важно:** держать `RTK_VERSION=1.1.0`. Сборки v1.2.0+ собраны под x86-64-v3 (AVX2) и падают SIGILL на этом хосте (Xeon X5670 — Westmere, без AVX). Перед обновлением проверять бинарь на хосте: `./rtk --version && ./rtk rewrite "git status"`.

Проверка в контейнере: `docker exec opencode-server rtk --version` и `docker exec opencode-server rtk rewrite "git status"`. Статистика экономии: `docker exec opencode-server rtk gain`.

## Автосборка образа

Настроен GitHub Actions (`.github/workflows/docker-build.yml`):
- Собирает образ каждый день в 3:00 по UTC
- При пуше в ветку `main` — **только если изменены `Dockerfile` или сам workflow** (фильтр `paths`): правки `docker-compose.yml`/доков не создают новый дайджест образа, чтобы watchtower не пересоздавал контейнер впустую
- При ручном запуске (`workflow_dispatch`)
- Образ пушится в `ghcr.io/<ваш-логин>/opencode-server:latest`

Чтобы использовать обновлённый образ:
```bash
docker compose pull
docker compose up -d
```

В `.env` нужно указать `GITHUB_USERNAME=<ваш-логин>`.
В настройках репозитория на GitHub (Settings → Actions → General) выберите **Read and write permissions** для Workflow permissions.

## Лучшие практики

Примонтированные каталоги (см. `docker-compose.yml`): `${WORKSPACE_DIR} → /workspace` (основное рабочее пространство, идексируется), `/mnt/media/docker-compose → /mnt/media/docker-compose` (старые compose-проекты, монтируются под тем же путём **вне** `/workspace`, чтобы не попадать в индексацию; старые проекты переносятся в `/workspace` постепенно), `.home → /home/node`, docker-сокет, `~/.gitconfig` и `~/.ssh` (ro).

- Секреты никогда не храните в репозитории. `.env` в `.gitignore`; реальные значения передавайте через `{env:ИМЯ}` / `{file:путь}` в конфиге или внешний `--env-file`.
- Не просите ИИ восстанавливать `.env` с реальными паролями — создавайте и редактируйте сами в терминале.
- Формат MCP в OpenCode 2.2.5: `mcp.servers.<имя>`, `command` — массив, обязательны `type` и `enabled`.
- Перезапускайте контейнер после любого изменения `opencode.json` или `.env`.
- Корень репозитория содержит только `docker-compose.yml`.

## Структура папки

```
docker-compose.yml      # основной файл
.env                    # переменные среды (gitignore, не коммитить)
.gitignore              # содержит .env
Dockerfile              # сборка образа OpenCode Server
.github/workflows/docker-build.yml   # автосборка образа
.home/.config/opencode/opencode.json   # MCP + LSP конфиг OpenCode
.home/.config/opencode/oh-my-opencode.json   # конфиг Oh My OpenCode
.home/.config/opencode/plugins/        # установленные плагины (oh-my-opencode)