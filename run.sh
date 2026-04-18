#!/usr/bin/env bash
# Run OpenCode in Docker, connected to local Ollama.
# Usage: ./run.sh [path/to/project]   (defaults to current directory)

PROJECT="${1:-$(pwd)}"
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

URL_FILE="${SCRIPT_DIR}/provider-url.txt"
if [ -f "$URL_FILE" ]; then
  OLLAMA_HOST=$(cat "$URL_FILE")
else
  echo "Error: provider-url.txt not found. Create it with your Ollama endpoint."
  exit 1
fi

# Extract hostname from URL and resolve to IP dynamically
HOSTNAME=$(echo "$OLLAMA_HOST" | sed -E 's|^https?://||' | cut -d':' -f1)
RESOLVED_IP=$(getent hosts "$HOSTNAME" 2>/dev/null | awk '{print $1; exit}')

if [ -z "$RESOLVED_IP" ]; then
  echo "Error: Could not resolve $HOSTNAME - check DNS/Tailscale connection"
  exit 1
fi

echo "Resolved $HOSTNAME to $RESOLVED_IP"

docker run -it --rm \
  --add-host "${HOSTNAME}:${RESOLVED_IP}" \
  -e GLAMOUR_STYLE=dark \
  -e OLLAMA_HOST="$OLLAMA_HOST" \
  -v "${PROJECT}:/workspace" \
  -w /workspace \
  -v "${SCRIPT_DIR}/opencode.json:/home/coder/.config/opencode/opencode.json:ro" \
  -v "${SCRIPT_DIR}/tui.json:/home/coder/.config/opencode/tui.json:ro" \
  -v "opencode-share:/home/coder/.local/share/opencode" \
  -v "opencode-state:/home/coder/.local/state/opencode" \
  -v "${HOME}/.gitconfig:/home/coder/.gitconfig:ro" \
  sancho
