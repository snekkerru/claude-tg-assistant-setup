#!/bin/bash
# Usage: transcribe.sh <audio_file_path>
# Returns transcribed text to stdout

set -e

AUDIO_FILE="$1"

if [ -z "$AUDIO_FILE" ]; then
  echo "Usage: transcribe.sh <audio_file_path>" >&2
  exit 1
fi

if [ ! -f "$AUDIO_FILE" ]; then
  echo "File not found: $AUDIO_FILE" >&2
  exit 1
fi

# Load GROQ_API_KEY from .env if not already set
if [ -z "$GROQ_API_KEY" ]; then
  source /home/claudeuser/.claude/channels/telegram/.env
fi

# .oga is OGG audio but Groq requires explicit .ogg extension
SEND_FILE="$AUDIO_FILE"
if [[ "$AUDIO_FILE" == *.oga ]]; then
  SEND_FILE="/tmp/$(basename "${AUDIO_FILE%.oga}").ogg"
  cp "$AUDIO_FILE" "$SEND_FILE"
fi

curl -s https://api.groq.com/openai/v1/audio/transcriptions \
  -H "Authorization: Bearer $GROQ_API_KEY" \
  -F "file=@${SEND_FILE}" \
  -F "model=whisper-large-v3-turbo" \
  -F "response_format=text"
