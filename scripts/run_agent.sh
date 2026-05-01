#!/bin/bash
# Agent runner script — customize for your own automated agents
# Usage: run_agent.sh <agent_name>

AGENT=$1
AGENTS_DIR="/home/claudeuser/.claude/agents"
STATE_DIR="/home/claudeuser/.claude/state"
ENV_FILE="/home/claudeuser/.claude/channels/telegram/.env"

if [ -f "$ENV_FILE" ]; then
  source "$ENV_FILE"
fi

BOT_TOKEN="${TELEGRAM_BOT_TOKEN}"
CHAT_ID="${TELEGRAM_CHAT_ID}"
MSK_TIME=$(TZ="Europe/Moscow" date +"%d.%m.%Y %H:%M")

send_tg() {
  curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    --data-urlencode "chat_id=${CHAT_ID}" \
    --data-urlencode "text=$1" \
    --data-urlencode "parse_mode=HTML" > /dev/null
}

if [ -z "$AGENT" ]; then
  echo "Usage: run_agent.sh <agent_name>"
  exit 1
fi

AGENT_FILE="${AGENTS_DIR}/${AGENT}.md"
if [ ! -f "$AGENT_FILE" ]; then
  send_tg "Agent ${AGENT}: config file not found (${AGENT_FILE})"
  exit 1
fi

# Add your agent-specific logic here
# Example:
# if [ "$AGENT" = "my_agent" ]; then
#   OUTPUT=$(claude --print "Your prompt here" 2>/dev/null)
#   send_tg "$OUTPUT"
# fi

send_tg "Agent ${AGENT} completed (${MSK_TIME})"
