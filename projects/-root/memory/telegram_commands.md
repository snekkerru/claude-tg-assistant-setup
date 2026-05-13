# Telegram Commands

## /clear

Clear Claude Code context window, as if `/clear` was typed in the terminal.

Steps:
1. Reply to Telegram: "контекст сброшен"
2. Run in background with delay so it fires after this reply is sent:
   `(sleep 4 && tmux send-keys -t claude-telegram "/clear" Enter) &`

## /model

Switch the active Claude Code model in the tmux session.

Accepted parameters: `sonnet` → `claude-sonnet-4-6`, `opus` → `claude-opus-4-7`.

Steps:
1. Parse the argument after `/model`. If missing or unrecognized, reply with usage hint and stop.
2. Map to full model ID:
   - `sonnet` → `claude-sonnet-4-6`
   - `opus` → `claude-opus-4-7`
3. Reply to Telegram: "модель переключена на <full-model-id>"
4. Run in background with delay so it fires after the reply:
   `(sleep 4 && tmux send-keys -t claude-telegram "/model <full-model-id>" Enter) &`

## /effort

Set the thinking effort level in the active Claude Code tmux session.

Accepted parameters: `low`, `medium`, `high`, `xhigh`, `max`, `auto`.

Steps:
1. Parse the argument after `/effort`. If missing or not in the list above, reply with usage hint and stop.
2. Reply to Telegram: "effort переключён на <level>"
3. Run in background with delay so it fires after the reply. Claude Code CLI shows a confirmation prompt, so send `y` + Enter to confirm:
   `(sleep 4 && tmux send-keys -t claude-telegram "/effort <level>" Enter && sleep 1 && tmux send-keys -t claude-telegram "y" Enter) &`

## /stat

Reply with three blocks — no prose, no padding:

**a) Model & effort** — model ID + effort level (e.g. `claude-sonnet-4-6 / high`).

**b) Context** — ASCII progress bar, estimated fill, absolute tokens:
```
[████████░░░░░░░░░░░░] ~42% (~84k / 200k)
```

**c) Token breakdown** — input / output / cache read / cache write.

Use monospace for numbers and bars. Flag estimates as approximate (~ prefix). If exact counts unavailable, show best estimates with ~.
