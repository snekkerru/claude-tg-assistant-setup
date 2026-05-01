#!/bin/bash
# Claude TG Assistant — interactive setup script
# Run as the user you want Claude to run under (e.g. claudeuser)

set -e

CLAUDE_DIR="$HOME/.claude"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ok()   { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}!${NC} $1"; }
ask()  { echo -e "\n${YELLOW}?${NC} $1"; }

echo ""
echo "================================================"
echo "  Claude TG Assistant — Setup"
echo "================================================"
echo ""

# ── 1. Check dependencies ─────────────────────────

echo "Checking dependencies..."

missing=()
for cmd in tmux expect curl git python3 bun; do
  if ! command -v "$cmd" &>/dev/null; then
    missing+=("$cmd")
  fi
done

if [ ${#missing[@]} -gt 0 ]; then
  warn "Missing: ${missing[*]}"
  echo "Install with:"
  echo "  sudo apt install -y tmux expect curl git python3"
  echo "  curl -fsSL https://bun.sh/install | bash && source ~/.bashrc"
  exit 1
fi

if ! command -v claude &>/dev/null; then
  warn "Claude Code CLI not found. Install:"
  echo "  npm install -g @anthropic-ai/claude-code --prefix ~/.local"
  echo "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc && source ~/.bashrc"
  exit 1
fi

ok "All dependencies found"

# ── 2. SSH key for GitHub ─────────────────────────

echo ""
echo "── SSH Key ──────────────────────────────────────"

if [ -f "$HOME/.ssh/github_ed25519" ]; then
  ok "SSH key already exists: $HOME/.ssh/github_ed25519"
else
  ask "Enter your email for SSH key (used for GitHub):"
  read -r GIT_EMAIL

  ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$HOME/.ssh/github_ed25519" -N ""

  cat >> "$HOME/.ssh/config" << EOF

Host github.com
  IdentityFile $HOME/.ssh/github_ed25519
  StrictHostKeyChecking no
EOF

  echo ""
  echo "Add this public key to GitHub → Settings → SSH keys:"
  echo ""
  cat "$HOME/.ssh/github_ed25519.pub"
  echo ""
  ask "Press Enter after adding the key to GitHub..."
  read -r
fi

# Verify GitHub connection
if ! ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
  warn "GitHub SSH auth failed. Check that you added the key correctly."
  exit 1
fi
ok "GitHub SSH connection works"

# ── 3. Clone repo ─────────────────────────────────

echo ""
echo "── Clone config ─────────────────────────────────"

if [ -d "$CLAUDE_DIR/.git" ]; then
  ok "~/.claude already exists and is a git repo — skipping clone"
else
  ask "Enter your claude-tg-assistant-setup repo SSH URL"
  echo "  (e.g. git@github.com:yourname/claude-tg-assistant-setup.git)"
  read -r REPO_URL

  git clone "$REPO_URL" "$CLAUDE_DIR"
  ok "Cloned to ~/.claude"
fi

ask "Enter your name for git commits:"
read -r GIT_NAME
ask "Enter your email for git commits:"
read -r GIT_EMAIL2

git -C "$CLAUDE_DIR" config user.name "$GIT_NAME"
git -C "$CLAUDE_DIR" config user.email "$GIT_EMAIL2"
ok "Git identity configured"

# ── 4. Telegram credentials ───────────────────────

echo ""
echo "── Telegram credentials ─────────────────────────"

ENV_FILE="$CLAUDE_DIR/channels/telegram/.env"

if [ -f "$ENV_FILE" ]; then
  ok ".env already exists — skipping"
else
  cp "$CLAUDE_DIR/channels/telegram/.env.example" "$ENV_FILE"

  ask "Telegram bot token (from @BotFather):"
  read -r TG_TOKEN

  ask "Your Telegram chat ID (send /start to @userinfobot to get it):"
  read -r TG_CHAT_ID

  ask "Groq API key (from console.groq.com, free tier):"
  read -r GROQ_KEY

  sed -i "s|your_bot_token_here|$TG_TOKEN|" "$ENV_FILE"
  sed -i "s|your_chat_id_here|$TG_CHAT_ID|" "$ENV_FILE"
  sed -i "s|your_groq_api_key_here|$GROQ_KEY|" "$ENV_FILE"

  ok "Telegram .env configured"
fi

# ── 5. Access control ─────────────────────────────

ACCESS_FILE="$CLAUDE_DIR/channels/telegram/access.json"
if [ ! -f "$ACCESS_FILE" ]; then
  cp "$CLAUDE_DIR/channels/telegram/access.json.example" "$ACCESS_FILE"
  ok "access.json created (configure allowed users via /telegram:access in Claude)"
else
  ok "access.json already exists"
fi

# ── 6. Tavily API key ─────────────────────────────

echo ""
echo "── MCP: Tavily ──────────────────────────────────"

if grep -q "YOUR_TAVILY_API_KEY" "$CLAUDE_DIR/settings.json"; then
  ask "Tavily API key (from tavily.com, optional — press Enter to skip):"
  read -r TAVILY_KEY

  if [ -n "$TAVILY_KEY" ]; then
    sed -i "s|YOUR_TAVILY_API_KEY|$TAVILY_KEY|" "$CLAUDE_DIR/settings.json"
    ok "Tavily key added to settings.json"
  else
    warn "Skipped — web search (Tavily) won't work until you add the key manually to ~/.claude/settings.json"
  fi
else
  ok "Tavily key already configured"
fi

# ── 7. Systemd service ────────────────────────────

echo ""
echo "── Systemd service ──────────────────────────────"

SERVICE_FILE="/etc/systemd/system/claude-telegram.service"
START_SCRIPT="$HOME/start-claude.sh"

cp "$CLAUDE_DIR/setup/start-claude.sh" "$START_SCRIPT"
chmod +x "$START_SCRIPT"

if [ ! -f "$SERVICE_FILE" ]; then
  # Replace $HOME placeholder in service file
  sed "s|/home/claudeuser|$HOME|g" "$CLAUDE_DIR/setup/claude-telegram.service" | \
    sudo tee "$SERVICE_FILE" > /dev/null
  sudo systemctl daemon-reload
  sudo systemctl enable claude-telegram
  sudo systemctl start claude-telegram
  ok "Systemd service installed and started"
else
  warn "Service already exists — skipping. Restart manually: sudo systemctl restart claude-telegram"
fi

# ── 8. Cron ───────────────────────────────────────

echo ""
echo "── Cron jobs ────────────────────────────────────"

CRON_JOB="7 0 * * * $CLAUDE_DIR/scripts/sync_to_github.sh >> $CLAUDE_DIR/sync_github.log 2>&1"
if ! crontab -l 2>/dev/null | grep -q "sync_to_github.sh"; then
  (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
  ok "GitHub sync cron added (daily 03:07 MSK)"
else
  ok "Cron already configured"
fi

# ── Done ──────────────────────────────────────────

echo ""
echo "================================================"
echo -e "  ${GREEN}Setup complete!${NC}"
echo "================================================"
echo ""
echo "Next steps:"
echo "  1. Run: claude"
echo "     → Authenticate with your claude.ai account"
echo "     → Use /telegram:access to approve your Telegram chat_id"
echo "  2. After first Claude run, apply the modified Telegram plugin:"
echo "     PLUGIN_DIR=\$(ls -d ~/.claude/plugins/cache/claude-plugins-official/telegram/*)"
echo "     cp ~/.claude/setup/telegram-server.ts \"\$PLUGIN_DIR/server.ts\""
echo "     sudo systemctl restart claude-telegram"
echo ""
echo "  Check status: sudo systemctl status claude-telegram"
echo "  Attach tmux:  tmux attach -t claude-telegram"
echo ""
