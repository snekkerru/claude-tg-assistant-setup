# Claude Agent — Setup from Scratch

Personal AI assistant running Claude Code via Telegram, with automated agents and GitHub config backup.

---

## What's in this repo

```
~/.claude/
├── CLAUDE.md                        # Main Claude instructions
├── settings.json                    # Claude Code settings + MCP servers
├── telegram_commands.md             # Telegram slash command definitions
├── transcribe.sh                    # Voice transcription helper
├── sync_to_github.sh                # Config backup script (runs nightly)
├── agents/                          # Specialist agent prompts
│   └── _routing.md                  # Agent routing index
├── scripts/
│   └── run_agent.sh                 # Automated agent runner (cron)
├── channels/telegram/
│   └── .env.example                 # Credentials template (copy to .env)
└── projects/-root/memory/           # Persistent memory files
    ├── MEMORY.md
    ├── user_profile.md
    ├── my_role.md
    ├── telegram_voice.md
    └── feedback_telegram_notifications.md
```

---

## Prerequisites

```bash
# System packages
apt install tmux expect curl git python3 -y

# Claude Code CLI — local install (auto-updates without root)
npm install -g @anthropic-ai/claude-code --prefix ~/.local
# Add to PATH (add to ~/.bashrc)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Bun (required for Telegram plugin)
curl -fsSL https://bun.sh/install | bash

# Add bun to PATH (add to ~/.bashrc)
echo 'export BUN_INSTALL="$HOME/.bun"' >> ~/.bashrc
echo 'export PATH="$BUN_INSTALL/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

---

## 1. Restore config from this repo

```bash
# Create user if needed
adduser claudeuser
su - claudeuser

# Clone into ~/.claude
git clone git@github.com:snekkerru/claude-template.git ~/.claude
```

> Note: SSH key for GitHub must be set up first (step 2) — or clone via HTTPS initially, then switch to SSH.

---

## 2. Set up SSH keys

```bash
# GitHub
ssh-keygen -t ed25519 -C "your@email.com" -f ~/.ssh/github_ed25519 -N ""
# Add ~/.ssh/github_ed25519.pub to github.com → Settings → SSH keys

cat >> ~/.ssh/config << 'EOF'
Host github.com
  IdentityFile /home/claudeuser/.ssh/github_ed25519
  StrictHostKeyChecking no
EOF

# Configure git
git -C ~/.claude config user.name "Your Name"
git -C ~/.claude config user.email "your@email.com"
```

---

## 3. Authenticate Claude Code

Claude uses OAuth (claude.ai account) — not an API key.

```bash
# Run once interactively to log in via browser
claude
# Follow the browser prompt to authenticate
# After login, Ctrl+C — auth is saved to ~/.claude.json
```

The MCP integrations (Notion, Slack, Google Calendar) are also linked via claude.ai — they activate automatically after login.

---

## 4. Set up Telegram plugin

```bash
# Create credentials file
cp ~/.claude/channels/telegram/.env.example ~/.claude/channels/telegram/.env
# Edit .env and fill in your values:
#   TELEGRAM_BOT_TOKEN — from @BotFather on Telegram
#   TELEGRAM_CHAT_ID   — your personal chat ID
#   GROQ_API_KEY       — from console.groq.com (free tier, for voice transcription)
nano ~/.claude/channels/telegram/.env

# Then run Claude and use /telegram:configure — paste the bot token
```

Set up access control (controls who can reach the bot):

```bash
cp ~/.claude/channels/telegram/access.json.example ~/.claude/channels/telegram/access.json
# Then in Claude: use /telegram:access to approve your own Telegram chat_id
```

After the plugin installs for the first time (on first Claude run), apply the modified server.ts to restore the `/stat` and `/clear` quick menu commands:

```bash
PLUGIN_DIR=$(ls -d ~/.claude/plugins/cache/claude-plugins-official/telegram/*)
cp ~/.claude/setup/telegram-server.ts "$PLUGIN_DIR/server.ts"
sudo systemctl restart claude-telegram
```

---

## 5. Configure MCP servers

Edit `~/.claude/settings.json` and replace `YOUR_TAVILY_API_KEY` with your real key:
- **Tavily** (web search): get key at tavily.com

- **Notion / Slack / Google Calendar**: connected via claude.ai account OAuth — log in at claude.ai and link the integrations

---

## 6. Set up systemd service

```bash
cp ~/.claude/setup/start-claude.sh ~/start-claude.sh
chmod +x ~/start-claude.sh

sudo cp /home/claudeuser/.claude/setup/claude-telegram.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable claude-telegram
sudo systemctl start claude-telegram
```

---

## 7. Set up cron jobs

```bash
crontab -e
```

Add:

```
# GitHub config sync — daily at 03:07 MSK (00:07 UTC)
7 0 * * * /home/claudeuser/.claude/sync_to_github.sh >> /home/claudeuser/.claude/sync_github.log 2>&1
```

---

## 8. Verify

```bash
tmux attach -t claude-telegram
bash ~/.claude/sync_to_github.sh
sudo systemctl status claude-telegram
```

---

## Config sync

The repo is updated automatically every night via `sync_to_github.sh`.

Secrets excluded: `.credentials.json`, `settings.local.json`, `channels/telegram/.env`.
