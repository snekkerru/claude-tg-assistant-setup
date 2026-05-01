# Telegram Commands

## /clear

Clear Claude Code context window, as if `/clear` was typed in the terminal.

Steps:
1. Reply to Telegram: "контекст сброшен"
2. Run in background with delay so it fires after this reply is sent:
   `(sleep 4 && tmux send-keys -t claude-telegram "/clear" Enter) &`

## /stat

Reply with three blocks — no prose, no padding:

**a) Model & effort** — model ID + effort level (e.g. `claude-sonnet-4-6 / high`).

**b) Context** — ASCII progress bar, estimated fill, absolute tokens:
```
[████████░░░░░░░░░░░░] ~42% (~84k / 200k)
```

**c) Token breakdown** — input / output / cache read / cache write.

Use monospace for numbers and bars. Flag estimates as approximate (~ prefix). If exact counts unavailable, show best estimates with ~.
