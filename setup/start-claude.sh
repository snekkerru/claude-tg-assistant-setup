#!/usr/bin/expect -f
spawn /home/claudeuser/.local/bin/claude --dangerously-skip-permissions --channels plugin:telegram@claude-plugins-official
expect "Enter to confirm"
send "\r"
interact
