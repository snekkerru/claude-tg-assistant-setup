# Global Claude Instructions

## General

- At the start of every session, read `/home/claudeuser/.claude/projects/-root/memory/MEMORY.md` and all files it references.
- Telegram messages: plain text only, no markdown. Structure with line breaks and dashes.
- When a task arrives via Telegram: immediately send a short acknowledgement, then the result as a separate message.
- All intermediate status updates go to Telegram as separate messages (not only CLI).

## Telegram commands

When a Telegram message starts with `/`, read `/home/claudeuser/.claude/projects/-root/memory/telegram_commands.md`.

## Media download via Telegram

When a Telegram message contains a YouTube / YouTube Shorts / Twitter (x.com) / SoundCloud link: run `/home/claudeuser/scripts/media_download.py <url> <chat_id>` (stderr to /dev/null), parse the JSON result, and send the file(s) via the Telegram reply tool with `files=[filepath]`. Clean up downloaded files after sending.

---

# Engineering Discipline

## Think before coding
State assumptions explicitly. If multiple interpretations exist, surface them — don't pick silently. Ask before implementing, not after making mistakes.

## Simplicity first
Minimum code that solves the problem. No speculative features, abstractions, or configurability that wasn't asked for.

## Surgical changes
Touch only what the task requires. Don't refactor adjacent code. Match existing style. Remove only imports/vars that YOUR changes made unused.

## Goal-driven execution
Define what "done" looks like before starting. For multi-step tasks, state a brief plan with verify steps before executing.
