#!/bin/bash
# Sync Claude config files to GitHub

set -e

REPO_DIR="/home/claudeuser/.claude"
source "${REPO_DIR}/channels/telegram/.env"
BOT_TOKEN="${TELEGRAM_BOT_TOKEN}"
CHAT_ID="${TELEGRAM_CHAT_ID}"
MSK_TIME=$(TZ="Europe/Moscow" date +"%d.%m.%Y %H:%M")

send_telegram() {
  curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    -d "chat_id=${CHAT_ID}" \
    -d "text=$1" > /dev/null
}

cd "$REPO_DIR"

git add -A

if git diff --cached --quiet; then
  send_telegram "GitHub sync — ${MSK_TIME} МСК: изменений нет"
  exit 0
fi

CHANGED=$(git diff --cached --name-only | head -20 | tr '\n' ', ' | sed 's/,$//')
COMMIT_MSG="auto sync $(TZ='Europe/Moscow' date +'%Y-%m-%d %H:%M') MSK"

git commit -m "$COMMIT_MSG"
git pull --rebase origin main
git push origin main

send_telegram "GitHub sync done — ${MSK_TIME} МСК
Обновлено: ${CHANGED}"
